"""Add UI strings to both locale files at once, so neither falls behind.

    python3 tool/add_strings.py strings.json

strings.json: {"key": {"fr": "...", "en": "...", "placeholders": {"n": "int"}}}
Placeholders are declared once, in the French template. Existing keys are
replaced, so the same file can be re-run after editing a translation.
"""

import json
import sys
from pathlib import Path

L10N = Path(__file__).resolve().parent.parent / "lib" / "l10n"


def main(path):
    new = json.loads(Path(path).read_text(encoding="utf-8"))
    for lang in ("fr", "en"):
        f = L10N / f"app_{lang}.arb"
        arb = json.loads(f.read_text(encoding="utf-8"))
        for key, spec in new.items():
            arb[key] = spec[lang]
            if lang == "fr" and spec.get("placeholders"):
                arb[f"@{key}"] = {"placeholders": {n: {"type": t} for n, t in spec["placeholders"].items()}}
        f.write_text(json.dumps(arb, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"{len(new)} strings added to fr and en")


if __name__ == "__main__":
    main(sys.argv[1])
