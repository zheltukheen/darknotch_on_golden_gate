#!/usr/bin/env python3
"""Checks that every translation file has the same keys and format tokens as en.json."""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
I18N = ROOT / "Resources" / "i18n"
TOKEN = re.compile(r"%(?:@|d|ld|s)")


def load(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> int:
    base = load(I18N / "en.json")
    base_strings = base["strings"]
    errors = []
    for path in sorted(I18N.glob("*.json")):
        data = load(path)
        strings = data.get("strings", {})
        if data.get("code") != path.stem:
            errors.append(f"{path.name}: code is {data.get('code')!r}, expected {path.stem!r}")
        missing = sorted(set(base_strings) - set(strings))
        extra = sorted(set(strings) - set(base_strings))
        if missing:
            errors.append(f"{path.name}: missing keys: {', '.join(missing)}")
        if extra:
            errors.append(f"{path.name}: extra keys: {', '.join(extra)}")
        for key in set(base_strings) & set(strings):
            if sorted(TOKEN.findall(base_strings[key])) != sorted(TOKEN.findall(strings[key])):
                errors.append(f"{path.name}: format tokens differ for {key}")
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(f"PASS: {len(list(I18N.glob('*.json')))} translation files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
