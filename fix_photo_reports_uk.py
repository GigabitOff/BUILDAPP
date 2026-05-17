from pathlib import Path

path = Path("lib/screens/modules/photo_reports_screen.dart")
text = path.read_text(encoding="utf-8")

replacements = {
    "Фотоотчётов пока нет": "Фотозвітів поки немає",
    "Нажми “Додати”, сделай фото или выбери его из галереи.": "Натисніть «Додати», зробіть фото або виберіть його з галереї.",
    "Нажми \"Додати\", сделай фото или выбери его из галереи.": "Натисніть «Додати», зробіть фото або виберіть його з галереї.",
    "Фотоотчёты": "Фотозвіти",
    "Фотоотчёт": "Фотозвіт",
    "фотоотчётов": "фотозвітів",
    "фотоотчёт": "фотозвіт",
    "сделай фото": "зробіть фото",
    "выбери его из галереи": "виберіть його з галереї",
}

for old, new in replacements.items():
    text = text.replace(old, new)

path.write_text(text, encoding="utf-8")
print("photo_reports_screen.dart fixed")
