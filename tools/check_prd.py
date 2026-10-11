"""Consistency check between docs/prd and tools/balance_sim.py.

    python tools/check_prd.py

Checks:
  1. Facility, stage, enemy, boss and forge-example numbers in the PRD match balance_sim.py.
  2. Every relative markdown link (file + #anchor) inside docs/ resolves to a real heading.
  3. Every player-facing string ID referenced in the PRD exists in docs/prd/strings.md.
Exit code 1 if anything fails.
"""
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
import balance_sim as b  # noqa: E402


def read(path):
    with open(os.path.join(ROOT, path), encoding="utf-8") as f:
        return f.read()


def check_numbers(errs):
    d07, d05, d04 = read("docs/prd/07-economy.md"), read("docs/prd/05-combat.md"), read("docs/prd/04-forge-system.md")
    lines07 = d07.splitlines()
    for lv in range(1, 11):
        row = next((l for l in lines07 if l.startswith(f"| {lv} |")), "")
        for fac in ("anvil", "furnace", "barracks"):
            if lv >= 2 and f"{b.UPGRADE_COST[fac][lv]:,}" not in row:
                errs.append(f"07 facility cost {fac} Lv{lv}")
        for v in (b.ANVIL_BUDGET[lv], b.FURNACE_MD[lv], b.FURNACE_ORE[lv], b.BARRACKS_HP[lv]):
            if f"| {v}" not in row and f" {v} " not in row:
                errs.append(f"07 facility value Lv{lv}={v}")
    tags = {"mushling": "M", "sprite": "S", "shellback": "Sh"}
    for s in range(1, 21):
        row = next((l for l in lines07 if re.match(rf"\| \**{s}\** \| (Mossy|Bramble)", l)), None)
        if row is None:
            errs.append(f"07 stage {s} row missing")
            continue
        fc, fo, fs = b.first_clear_reward(s)
        rc, ro = b.idle_rate(s)
        a, f, br, _ = b.EXPECTED[s]
        if f"{fc} / {fo} / {fs}" not in row:
            errs.append(f"07 stage {s} first clear")
        if f"{rc:.2f} / {ro:.3f}" not in row:
            errs.append(f"07 stage {s} cart rate")
        if f"| {a}/{f}/{br} |" not in row:
            errs.append(f"07 stage {s} expected state")
        for wave in b.STAGES[s]:
            for kind, n, _side in wave:
                if kind in tags and f"{tags[kind]}×{n}" not in row:
                    errs.append(f"07 stage {s} wave {kind}×{n}")
    for s in (1, 3, 5, 6, 8, 10, 12, 15, 17, 20):
        m, sp, sh = (b.enemy_stats(k, s) for k in ("mushling", "sprite", "shellback"))
        expect = (f"| {s} | {m['hp']} / {m['dmg']} | {sp['hp']} / {sp['dmg']} | "
                  f"{sh['hp']} / {sh['armor']} / {sh['dmg']} |")
        if expect not in d05:
            errs.append(f"05 enemy stats stage {s}")
    for kind in ("queen", "ironhide", "thornwarden", "warden_elite"):
        if f"HP {b.ENEMIES[kind]['hp']}" not in d05:
            errs.append(f"05 boss HP {kind}")
    examples = [("E1", 10, 2, 2, 0, None, 1), ("E2", 10, 4, 3, 0, None, 2), ("E3", 12, 3, 1, 3, "Ember", 2),
                ("E4", 12, 8, 0, 0, None, 3), ("E5", 20, 3, 4, 3, "Ember", 5), ("E6", 28, 3, 5, 3, "Spark", 0),
                ("E7", 24, 3, 6, 0, None, 4)]
    for name, md, bp, hp, rp, rune, t in examples:
        w = b.weapon(md, bp, hp, rp, rune, t)
        parts = d04.split(f"### 算例 {name}")
        if len(parts) < 2:
            errs.append(f"04 example {name} missing")
            continue
        sec = parts[1].split("### 算例")[0]
        if f"**{w['H']}**" not in sec:
            errs.append(f"04 example {name} H={w['H']}")
        if f"**{w['I']:.2f} s**" not in sec:
            errs.append(f"04 example {name} I={w['I']:.2f}")


def slug(text):
    text = re.sub(r"[^\w\- ]", "", text.strip().lower())
    return text.replace(" ", "-")


def anchors(path):
    out = set()
    for line in read(path).splitlines():
        m = re.match(r"^(#{1,6})\s+(.*)$", line)
        if m:
            out.add(slug(m.group(2)))
    return out


def check_links(errs):
    files = [os.path.relpath(p, ROOT).replace("\\", "/") for p in glob.glob(os.path.join(ROOT, "docs/**/*.md"), recursive=True)]
    files.append("README.md")
    for f in files:
        base = os.path.dirname(f)
        for target in re.findall(r"\]\(([^)\s]+)\)", read(f)):
            if target.startswith(("http://", "https://", "mailto:")):
                continue
            path, _, anchor = target.partition("#")
            dest = os.path.normpath(os.path.join(base, path)).replace("\\", "/") if path else f
            if not os.path.exists(os.path.join(ROOT, dest)):
                errs.append(f"{f}: missing file {target}")
                continue
            if anchor and dest.endswith(".md") and anchor not in anchors(dest):
                errs.append(f"{f}: missing anchor {target}")


STRING_PREFIXES = ("btn_", "tut_", "forge_form", "forge_zone", "forge_unused", "forge_reset", "forge_rune_every",
                   "forge_perfect", "forge_strikes", "defeat_", "err_", "cart_full", "cart_title", "welcome_",
                   "offer_", "supply_", "survey_", "smelt_", "rack_full", "rack_all", "rune_ember_desc",
                   "rune_unlocked", "boss_gate_title", "boss_queen_hint", "victory_", "hint_suggested",
                   "hits_per_swing", "deliver_changed", "swap_cooldown", "upgrade_", "stone_overflow", "push_",
                   "att_preprompt", "store_tagline", "iap_pending", "iap_failed", "iap_restored", "ad_limit",
                   "ad_not_ready", "net_offline", "farm_label", "wave_summary", "reforge_stone", "qf_", "title_")


def check_strings(errs):
    defined = {i.split("#")[0] for i in re.findall(r"^\| `([a-z0-9_#]+)`", read("docs/prd/strings.md"), re.M)}
    # telemetry event names (first column of the 11.1 table) are not player-facing strings
    events = set(re.findall(r"`([a-z_]+)`", " ".join(
        l.split("|")[1] for l in read("docs/prd/11-data-validation.md").splitlines() if l.startswith("| `"))))
    for p in glob.glob(os.path.join(ROOT, "docs/prd/*.md")):
        if p.endswith("strings.md"):
            continue
        rel = os.path.relpath(p, ROOT)
        for sid in re.findall(r"`([a-z][a-z0-9_]+)`", read(rel)):
            if sid.startswith(STRING_PREFIXES) and sid not in defined and sid not in events:
                errs.append(f"{rel}: string id `{sid}` not in strings.md")


if __name__ == "__main__":
    problems = []
    check_numbers(problems)
    check_links(problems)
    check_strings(problems)
    if problems:
        print("\n".join(sorted(set(problems))))
        sys.exit(1)
    print("PRD consistency: all checks passed")
