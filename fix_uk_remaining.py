from pathlib import Path

replacements = {
    "Введите email и пароль": "Введіть email і пароль",
    "Введите email": "Введіть email",
    "Введите пароль": "Введіть пароль",
    "Ошибка обновления уведомления": "Помилка оновлення сповіщення",
}

paths = [
    Path("lib/screens/login_screen.dart"),
    Path("lib/services/notifications_service.dart"),
]

for path in paths:
    text = path.read_text(encoding="utf-8")
    original = text

    for old, new in replacements.items():
        text = text.replace(old, new)

    if text != original:
        path.write_text(text, encoding="utf-8")
        print(f"UPDATED: {path}")

print("Done")
