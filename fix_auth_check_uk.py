from pathlib import Path

path = Path("lib/screens/modules/auth_check_screen.dart")
text = path.read_text(encoding="utf-8")

replacements = {
    "Проверка авторизации": "Перевірка авторизації",
    "Проверка токена": "Перевірка токена",
    "Нажми кнопку, чтобы проверить токен через /api/me": "Натисніть кнопку, щоб перевірити токен через /api/me",
    "Проверить токен": "Перевірити токен",
}

for old, new in replacements.items():
    text = text.replace(old, new)

path.write_text(text, encoding="utf-8")
print("auth_check_screen.dart fixed")
