"""Export the player-facing English strings from docs/prd/strings.md for the iOS client.

    python tools/export_strings.py          # write ios/GoblinForge/Resources/strings.json
    python tools/export_strings.py --check  # exit 1 if the committed file is out of date

strings.md is the single source of truth (CLAUDE.md). Plural forms keep their `#one` / `#other`
suffix as separate keys; the client picks one with the CLDR English rule (1 -> one, else other).
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs/prd/strings.md"
TARGET = ROOT / "ios/GoblinForge/Resources/strings.json"
ROW = re.compile(r"^\| `([a-z0-9_]+(?:#one|#other)?)` \| (.*?) \| (.*?) \| (.*?) \|\s*$")


def load():
    strings = {}
    for line in SOURCE.read_text(encoding="utf-8").splitlines():
        match = ROW.match(line)
        if not match:
            continue
        key, text = match.group(1), match.group(2).strip()
        if key in strings:
            raise SystemExit(f"duplicate string id: {key}")
        if re.search(r"[一-鿿]", text):
            raise SystemExit(f"Chinese text in player-facing string: {key}")
        strings[key] = text
    for key in list(strings):
        base, _, form = key.partition("#")
        if form and (f"{base}#one" not in strings or f"{base}#other" not in strings):
            raise SystemExit(f"plural pair incomplete: {base}")
    return strings


def render(strings):
    return json.dumps(dict(sorted(strings.items())), ensure_ascii=False, indent=1) + "\n"


def main(argv):
    text = render(load())
    if "--check" in argv:
        current = TARGET.read_text(encoding="utf-8") if TARGET.exists() else ""
        if current != text:
            print(f"FAILED: {TARGET.relative_to(ROOT)} is out of date; run python tools/export_strings.py")
            return 1
        print(f"OK: {TARGET.relative_to(ROOT)} matches docs/prd/strings.md ({len(json.loads(text))} ids)")
        return 0
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    TARGET.write_text(text, encoding="utf-8", newline="\n")
    print(f"wrote {TARGET.relative_to(ROOT)} ({len(json.loads(text))} ids)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
