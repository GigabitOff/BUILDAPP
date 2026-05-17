from pathlib import Path

path = Path("lib/screens/pin_code_screen.dart")
text = path.read_text(encoding="utf-8")

replacements = {
    "вЂў": "•",
    "Р’зменить номер телефона": "Изменить номер телефона",
    "Рменить номер телефона": "Изменить номер телефона",
}

for old, new in replacements.items():
    text = text.replace(old, new)

path.write_text(text, encoding="utf-8")
print("pin_code_screen.dart fixed")
