from pathlib import Path

roots = [Path("lib"), Path("android")]

files = []

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

        files.append(p)

changed = 0
skipped = 0

for p in files:
    try:
        text = p.read_text(encoding="utf-8")

        # Исправление mojibake: РџСЂ... -> нормальный русский/украинский текст
        fixed = text.encode("cp1251").decode("utf-8")

        if fixed != text:
            p.write_text(fixed, encoding="utf-8")
            changed += 1
            print(f"FIXED: {p}")

    except UnicodeEncodeError:
        skipped += 1
        print(f"SKIP unicode chars not cp1251: {p}")
    except Exception as e:
        skipped += 1
        print(f"SKIP {p}: {e}")

print(f"Done. Changed: {changed}, skipped: {skipped}")
