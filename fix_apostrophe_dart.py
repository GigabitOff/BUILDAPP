from pathlib import Path

replacements = {
    "об'є": "об’є",
    "Об'є": "Об’є",
    "об'е": "об’є",
    "Об'е": "Об’є",
}

for path in Path("lib").rglob("*.dart"):
    text = path.read_text(encoding="utf-8")
    new_text = text

    for old, new in replacements.items():
        new_text = new_text.replace(old, new)

    if new_text != text:
        path.write_text(new_text, encoding="utf-8")
        print(f"fixed apostrophe: {path}")

print("done")
