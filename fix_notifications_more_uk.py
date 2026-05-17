from pathlib import Path

path = Path("lib/screens/modules/notifications_screen.dart")
text = path.read_text(encoding="utf-8")

replacements = {
    "Все уведомления отмечены прочитанными": "Усі сповіщення позначені як прочитані",
    "Показать все": "Показати всі",
    "Только непрочитанные": "Тільки непрочитані",
    "Отметить все прочитанными": "Позначити всі як прочитані",
}

for old, new in replacements.items():
    text = text.replace(old, new)

path.write_text(text, encoding="utf-8")
print("notifications_screen.dart fixed")
