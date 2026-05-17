from pathlib import Path

replacements = {
    "Объект добавлен": "Об'єкт додано",
    "Объект строительства": "Об'єкт будівництва",
    "Объект": "Об'єкт",
    "объект": "об'єкт",

    "Ошибка создания приглашения": "Помилка створення запрошення",
    "Ошибка удаления фотозвіта": "Помилка видалення фотозвіту",

    "будет скрыт из приложения": "буде прихований із застосунку",
}

for path in Path("lib").rglob("*.dart"):
    text = path.read_text(encoding="utf-8")

    new_text = text
    for old, new in replacements.items():
        new_text = new_text.replace(old, new)

    if new_text != text:
        path.write_text(new_text, encoding="utf-8")
        print(f"fixed: {path}")

print("done")
