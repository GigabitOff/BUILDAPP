from pathlib import Path

roots = [Path("lib"), Path("android")]

# Русский + украинский алфавит и типовая пунктуация, которая тоже ломается
chars = (
    "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ"
    "абвгдеёжзийклмнопрстуфхцчшщъыьэюя"
    "ІіЇїЄєҐґ"
    "№«»—–…“”„’‘"
)

mapping = {}

for ch in chars:
    try:
        broken = ch.encode("utf-8").decode("cp1251")
        if broken != ch:
            mapping[broken] = ch
    except Exception:
        pass

# Частые поломки пробела/кавычек
manual = {
    "В«": "«",
    "В»": "»",
    "В ": " ",
    "в„–": "№",
    "вЂ”": "—",
    "вЂ“": "–",
    "вЂ¦": "…",
    "вЂњ": "“",
    "вЂќ": "”",
    "вЂћ": "„",
    "вЂ™": "’",
    "вЂ�": "‘",
}

mapping.update(manual)

# Важно: длинные последовательности первыми
items = sorted(mapping.items(), key=lambda x: len(x[0]), reverse=True)

changed_files = 0
total_replacements = 0

for root in roots:
    if not root.exists():
        continue

    for p in root.rglob("*"):
        if not p.is_file():
            continue

        path_str = str(p)

        if "\\.gradle\\" in path_str or "\\build\\" in path_str or "\\.dart_tool\\" in path_str:
            continue

        if p.suffix.lower() not in [".dart", ".xml", ".gradle", ".kt", ".java"]:
            continue

        try:
            text = p.read_text(encoding="utf-8")
        except Exception as e:
            print(f"SKIP READ {p}: {e}")
            continue

        fixed = text
        replacements = 0

        for broken, good in items:
            count = fixed.count(broken)
            if count:
                fixed = fixed.replace(broken, good)
                replacements += count

        if fixed != text:
            p.write_text(fixed, encoding="utf-8")
            changed_files += 1
            total_replacements += replacements
            print(f"FIXED {p} replacements={replacements}")

print(f"Done. Changed files: {changed_files}, replacements: {total_replacements}")
