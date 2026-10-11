"""M0 prototype case calibration (PRD 0.3, backlog M0-04).

    python tools/prototype_cases.py                 # markdown report for every case in the config
    python tools/prototype_cases.py --json          # machine-readable results
    python tools/prototype_cases.py --check         # exit 1 if a transfer/learning case misses the 0.3 rule
    python tools/prototype_cases.py --try learn_swarm "Broad B4/H6"   # one-off build, seeds 1-10

The cases live in config/prototype/m0_cases.json (same file the iOS client bundles). Battles run through
tools/balance_sim.simulate() unchanged: the case waves temporarily replace STAGES[growth_stage] so enemy
growth, spawn RNG (seed * 1000 + growth_stage), armor/guard/burn rules and time limits are exactly the
simulator's. The demo case (HP floor, looping waves) is client-only and is not calibrated here.

PRD 0.3 rule for each transfer case: at least 2 registered answers that differ in behaviour, each winning
>= 8 of seeds 1-10; the starting weapon wins <= 2 of the same seeds. Learning cases use the same report
so Codex can tune them; this tool does not decide the numbers.
"""
import contextlib
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import balance_sim as b  # noqa: E402

CONFIG = ROOT / "config/prototype/m0_cases.json"
SEEDS = range(1, 11)
MIN_ANSWER_WINS, MAX_START_WINS = 8, 2


def load():
    return json.loads(CONFIG.read_text(encoding="utf-8"))


def weapon(case, spec):
    rune = spec.get("rune")
    return b.weapon(case["md"], spec["b"], spec["h"], spec.get("r", 0), rune.capitalize() if rune else None,
                    min(b.TEMPER_BASELINE, spec["b"] + spec["h"] + spec.get("r", 0)))


def parse_build(case, text):
    m = re.fullmatch(r"\s*\w+\s+B(\d+)/H(\d+)(?:/R(\d+))?(?:\s+(\w+))?\s*", text)
    if not m:
        raise SystemExit(f"cannot parse build {text!r}; use e.g. 'Broad B4/H6' or 'Needle B3/H4/R3 Ember'")
    spec = {"b": int(m.group(1)), "h": int(m.group(2)), "r": int(m.group(3) or 0), "rune": m.group(4)}
    return weapon(case, spec)


@contextlib.contextmanager
def case_stage(case):
    key = case["growth_stage"]
    saved = b.STAGES[key]
    b.STAGES[key] = [[(kind, n, side) for kind, n, side in wave] for wave in case["waves"]]
    try:
        yield key
    finally:
        b.STAGES[key] = saved


def run(case, wpn, seed):
    with case_stage(case) as stage:
        return b.simulate(stage, wpn, case["hero_hp"], seed)


def evaluate(case):
    rows = []
    start = weapon(case, case["initial_rack"][0])
    candidates = [("start", start)] + [(a["label"], weapon(case, a)) for a in case.get("answers", [])]
    for role, w in candidates:
        results = [run(case, w, s) for s in SEEDS]
        rows.append({
            "role": "start" if role == "start" else "answer", "label": w["label"],
            "behaviour": f"{w['form']}{('+' + w['rune']) if w['rune'] else ''}",
            "wins": sum(r["win"] for r in results),
            "avg_t": round(sum(r["t"] for r in results) / len(results), 1),
            "avg_hp": round(sum(max(r["hp"], 0) for r in results) / len(results), 1),
            "per_seed": ["W" if r["win"] else ("T" if r.get("timeout") else "L") for r in results],
        })
    return rows


def verdict(case, rows):
    if case["kind"] not in ("transfer", "learning"):
        return "n/a", []
    problems = []
    start = rows[0]
    answers = [r for r in rows if r["role"] == "answer"]
    if start["wins"] > MAX_START_WINS:
        problems.append(f"start weapon wins {start['wins']}/10 (> {MAX_START_WINS})")
    good = [r for r in answers if r["wins"] >= MIN_ANSWER_WINS]
    if len(good) < 2:
        problems.append(f"only {len(good)} registered answers win >= {MIN_ANSWER_WINS}/10")
    elif len({r["behaviour"] for r in good}) < 2:
        problems.append("winning answers do not differ in behaviour (same form and rune)")
    return ("PASS" if not problems else "FAIL"), problems


REFERENCE = ROOT / "tools/reference/prototype_reference.json"


def reference_rows(config):
    """Per-seed results the Swift client must reproduce (tests in Packages/GoblinForgeCore)."""
    rows = []
    for case in config["cases"]:
        if case["kind"] == "demo":
            continue
        for spec in case["initial_rack"][:1] + case.get("answers", []):
            w = weapon(case, spec)
            for seed in SEEDS:
                r = run(case, w, seed)
                rows.append({"case": case["id"], "b": spec["b"], "h": spec["h"], "r": spec.get("r", 0),
                             "rune": spec.get("rune"), "seed": seed, "win": r["win"], "t": r["t"],
                             "hero_hp": max(r["hp"], 0), "wave": r["wave"]})
    lines = [json.dumps(row, separators=(",", ":")) for row in rows]
    header = '{\n "config_version": ' + json.dumps(config["config_version"]) + ',\n "results": [\n  '
    return header + ",\n  ".join(lines) + "\n ]\n}\n"


def main(argv):
    config = load()
    cases = {c["id"]: c for c in config["cases"]}
    if "--write-reference" in argv or "--check-reference" in argv:
        text = reference_rows(config)
        if "--check-reference" in argv:
            ok = REFERENCE.exists() and REFERENCE.read_text(encoding="utf-8") == text
            print(("OK: " if ok else "FAILED: ") + f"{REFERENCE.relative_to(ROOT)}"
                  + ("" if ok else " is out of date; run python tools/prototype_cases.py --write-reference"))
            return 0 if ok else 1
        REFERENCE.write_text(text, encoding="utf-8", newline="\n")
        print(f"wrote {REFERENCE.relative_to(ROOT)}")
        return 0
    if "--try" in argv:
        i = argv.index("--try")
        case = cases[argv[i + 1]]
        w = parse_build(case, argv[i + 2])
        results = [run(case, w, s) for s in SEEDS]
        print(w["label"], f"H {w['H']} I {w['I']}", "".join("W" if r["win"] else "L" for r in results),
              f"wins {sum(r['win'] for r in results)}/10")
        return 0
    report = {"config_version": config["config_version"], "cases": []}
    failed = False
    for case in config["cases"]:
        if case["kind"] == "demo":
            continue
        rows = evaluate(case)
        status, problems = verdict(case, rows)
        failed |= status == "FAIL" and case["kind"] == "transfer"
        report["cases"].append({"id": case["id"], "kind": case["kind"], "status": status, "problems": problems,
                                "rows": rows})
    if "--json" in argv:
        print(json.dumps(report, indent=1))
    else:
        print(f"# M0 case calibration ({config['config_version']}, seeds 1-10)\n")
        print("Rule (PRD 0.3): >= 2 behaviourally different answers, each >= 8/10 wins; start weapon <= 2/10.\n")
        for c in report["cases"]:
            print(f"## {c['id']} ({c['kind']}): {c['status']}")
            for p in c["problems"]:
                print(f"- {p}")
            print("\n| Role | Build | Wins/10 | Avg time s | Avg hero HP | Seeds 1-10 |\n|---|---|---|---|---|---|")
            for r in c["rows"]:
                print(f"| {r['role']} | {r['label']} | {r['wins']} | {r['avg_t']} | {r['avg_hp']} | {''.join(r['per_seed'])} |")
            print()
    if "--check" in argv and failed:
        print("FAILED: a transfer case does not meet PRD 0.3", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
