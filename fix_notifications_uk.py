from pathlib import Path

path = Path("lib/screens/modules/notifications_screen.dart")
text = path.read_text(encoding="utf-8")

replacements = {
    "Уведомлений пока нет": "Сповіщень поки немає",
    "Когда по объектам будут изменения, они появятся здесь.": "Коли по об’єктах будуть зміни, вони з’являться тут.",
    "Уведомления": "Сповіщення",
    "Отметить все как прочитанные": "Позначити всі як прочитані",
    "Все уведомления прочитаны": "Усі сповіщення прочитані",
    "Нет уведомлений": "Немає сповіщень",
}

for old, new in replacements.items():
    text = text.replace(old, new)

path.write_text(text, encoding="utf-8")
print("notifications_screen.dart fixed")
