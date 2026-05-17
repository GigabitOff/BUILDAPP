from pathlib import Path

path = Path("lib/screens/modules/tasks_screen.dart")
text = path.read_text(encoding="utf-8")

replacements = {
    "Задач пока нет": "Завдань поки немає",
    "Когда задачи появятся на объектах, они будут здесь одним списком.": "Коли завдання з’являться на об’єктах, вони будуть тут одним списком.",
    "Задачи": "Завдання",
    "задач": "завдань",
    "задачи": "завдання",
    "задача": "завдання",
}

for old, new in replacements.items():
    text = text.replace(old, new)

path.write_text(text, encoding="utf-8")
print("tasks_screen.dart fixed")
