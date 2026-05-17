from pathlib import Path

replacements = {
    "Рполнитель": "Исполнитель",
    "Рменения по объектам": "Изменения по объектам",
    "Рменить номер телефона": "Изменить номер телефона",
}

files = [
    Path("lib/models/app_user.dart"),
    Path("lib/screens/home_screen.dart"),
    Path("lib/screens/pin_code_screen.dart"),
]

for path in files:
    text = path.read_text(encoding="utf-8")
    original = text

    for old, new in replacements.items():
        text = text.replace(old, new)

    if text != original:
        path.write_text(text, encoding="utf-8")
        print(f"FIXED: {path}")

print("Done")
