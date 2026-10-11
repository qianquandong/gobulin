"""Export expected values from tools/balance_sim.py for the Swift rules package to compare against.

    python tools/export_core_reference.py          # write tools/reference/core_reference.json
    python tools/export_core_reference.py --check  # exit 1 if the committed file is out of date

The Swift tests (Packages/GoblinForgeCore) load this file and must reproduce every value exactly
(integers) or to the stated precision (floats). The simulator stays the source of truth: change a
number in balance_sim.py, rerun this script, and the Swift tests show what must follow.

Generate it on Linux (glibc), the same platform as CI, e.g.

    docker run --rm -v "$PWD:/gobulin" -w /gobulin python:3.12-slim python tools/export_core_reference.py

math.cos / math.sin / math.atan2 come from the platform libm. On 2026-10-11 a Windows build of the same
simulator differed from Linux in the last bit of sin() for 13 of the 200 trig probes, which changed one of
the 453 battles (stage 19, seed 2, Needle+Spark: 43.1 s / 148 HP vs 42.4 s / 153 HP; still a win).
math.hypot is CPython's own algorithm and matched exactly.
"""
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import balance_sim as b  # noqa: E402

TARGET = ROOT / "tools/reference/core_reference.json"


def weapon_row(md, bp, hp, rp, rune, temper):
    w = b.weapon(md, bp, hp, rp, rune, temper)
    burn = None
    if rune == "Ember":
        import math
        burn = math.ceil(w["H"] * b.EMBER_RATIO / 3)
    return {"md": md, "bp": bp, "hp": hp, "rp": rp, "rune": rune.lower() if rune else None, "temper": temper,
            "form": w["form"].lower(), "H": w["H"], "I": w["I"], "W": w["W"], "every": w["every"],
            "burn": burn, "label": w["label"]}


def weapons():
    rows = []
    for md in b.FURNACE_MD.values():
        for bp in range(b.BLADE_CAP + 1):
            for hp in range(b.HILT_CAP + 1):
                rows.append(weapon_row(md, bp, hp, 0, None, b.TEMPER_BASELINE))
    for md in (10, 20):
        for bp in range(b.BLADE_CAP + 1):
            for hp in range(b.HILT_CAP + 1):
                for temper in (0, 1, 2, 5, 10, 11):
                    rows.append(weapon_row(md, bp, hp, 0, None, temper))
    for md in (12, 20, 28):
        for bp in range(b.BLADE_CAP + 1):
            for hp in range(b.HILT_CAP + 1):
                for rp in range(1, b.RUNE_CAP + 1):
                    if bp + hp + rp <= 14:
                        # 元素只影响标签与灼烧；Frost / Spark 只在一个 MD 上覆盖
                        for rune in (("Ember", "Frost", "Spark") if md == 28 else ("Ember",)):
                            rows.append(weapon_row(md, bp, hp, rp, rune, b.TEMPER_BASELINE))
    return rows


def worked_examples():
    """PRD 4.9 E1-E7, exactly as report_weapons() prints them."""
    rows = [("E1", 10, 2, 2, 0, None, 1), ("E2", 10, 4, 3, 0, None, 2), ("E3", 12, 3, 1, 3, "Ember", 2),
            ("E4", 12, 8, 0, 0, None, 3), ("E5", 20, 3, 4, 3, "Ember", 5), ("E6", 28, 3, 5, 3, "Spark", 0),
            ("E7", 24, 3, 6, 0, None, 4)]
    return [dict(weapon_row(md, bp, hp, rp, rune, tem), example=name) for name, md, bp, hp, rp, rune, tem in rows]


def random_probes():
    """Python random.Random streams the Swift port (PyRandom) must reproduce bit for bit."""
    import random
    rows = []
    for seed in (0, 1, 7, 1008, 2020, 3005, 4294967295, 4294967296, 123456789012):
        r = random.Random(seed)
        values = [r.random() for _ in range(5)]
        uniform = [r.uniform(-35, 35) for _ in range(5)] + [r.uniform(0, 360) for _ in range(3)]
        deck = list(range(12))
        r.shuffle(deck)
        bits = [r.getrandbits(k) for k in (1, 5, 13, 32)]
        rows.append({"seed": seed, "random": values, "uniform": uniform, "shuffle": deck, "bits": bits})
    return rows


def math_probes():
    """math.hypot (CPython vector_norm), cos/sin/atan2 values on the generating platform."""
    import math
    import random
    r = random.Random(42)
    hyp, trig = [], []
    for _ in range(400):
        x, y = r.uniform(-7, 7), r.uniform(-7, 7)
        hyp.append([x, y, math.hypot(x, y)])
    for x, y in ((3.0, 4.0), (0.0, 0.0), (1e-300, 1e-300), (6.5, 0.0), (0.1, 0.2), (5e-324, 0.0)):
        hyp.append([x, y, math.hypot(x, y)])
    for _ in range(200):
        deg = r.uniform(-400, 400)
        a = math.radians(deg)
        x, y = r.uniform(-7, 7), r.uniform(-7, 7)
        trig.append([deg, math.cos(a), math.sin(a), x, y, math.atan2(y, x), math.degrees(math.atan2(y, x))])
    return {"hypot": hyp, "trig": trig}


def enemy_rows():
    rows = []
    for kind in b.ENEMIES:
        for stage in range(1, 21):
            e = b.enemy_stats(kind, stage)
            rows.append({"kind": kind, "stage": stage, "hp": e["hp"], "armor": e["armor"], "dmg": e["dmg"]})
    return rows


def battles(seeds=(1, 2, 3)):
    """Every representative build on every stage, exactly as report_stages() runs them."""
    rows = []
    for s in sorted(b.STAGES):
        a, f, br, runes = b.EXPECTED[s]
        budget, md, hero = b.ANVIL_BUDGET[a], b.FURNACE_MD[f], b.BARRACKS_HP[br]
        if s <= 2:
            runes = ()
        for w in b.builds_for(budget, md, runes):
            for seed in seeds:
                r = b.simulate(s, w, hero, seed)
                lg = r["log"]
                rows.append({
                    "stage": s, "seed": seed, "hero": hero, "md": w["md"], "bp": w["bp"], "hp": w["hp"], "rp": w["rp"],
                    "rune": w["rune"].lower() if w["rune"] else None, "temper": w["temper"], "label": w["label"],
                    "win": r["win"], "t": r["t"], "hero_hp": r["hp"], "wave": r["wave"], "left": r["left"],
                    "timeout": bool(r.get("timeout")), "boss_t": r.get("boss_t"),
                    "log": [lg["blocked_by_guard"], lg["armor_absorbed"], lg["dealt"], lg["burn"], lg["hits"],
                            lg["swings"], lg["max_engaged"], lg["taken"], lg["triggers"]],
                })
    return rows


def build():
    return {
        "source": "tools/balance_sim.py",
        "examples": worked_examples(),
        "random": random_probes(),
        "enemies": enemy_rows(),
        "battles": battles(),
        "math": math_probes(),
        "weapons": weapons(),
    }


def render(data):
    # One weapon per line keeps diffs readable while staying valid JSON.
    lines = ["{", f' "source": {json.dumps(data["source"])},']
    keys = [k for k in data if k != "source"]
    for n, key in enumerate(keys):
        last = n == len(keys) - 1
        if isinstance(data[key], dict):
            lines.append(f' "{key}": {json.dumps(data[key], separators=(",", ":"))}' + ("" if last else ","))
            continue
        lines.append(f' "{key}": [')
        items = [json.dumps(row, separators=(",", ":")) for row in data[key]]
        lines += ["  " + item + ("," if i < len(items) - 1 else "") for i, item in enumerate(items)]
        lines.append(" ]" + ("" if last else ","))
    lines.append("}")
    return "\n".join(lines) + "\n"


def main(argv):
    text = render(build())
    json.loads(text)
    if "--check" in argv:
        current = TARGET.read_text(encoding="utf-8") if TARGET.exists() else ""
        if current != text:
            print(f"FAILED: {TARGET.relative_to(ROOT)} is out of date; run python tools/export_core_reference.py")
            return 1
        print(f"OK: {TARGET.relative_to(ROOT)} matches tools/balance_sim.py")
        return 0
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    TARGET.write_text(text, encoding="utf-8", newline="\n")
    print(f"wrote {TARGET.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
