import json
import re
from pathlib import Path
from datetime import datetime

in_path = Path(r"Besmele/data/daily_panel/publish/hadiths.v1.approved.json")
if not in_path.exists():
    print('Input file not found:', in_path)
    raise SystemExit(1)

timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
backup_path = in_path.with_name(in_path.name + f'.bak.{timestamp}')

print(f"Loading {in_path}")
obj = json.loads(in_path.read_text(encoding='utf-8'))
records = obj.get('records', [])

# patterns and replacements
replacements = [
    (re.compile(r"\\(ra\\)", re.IGNORECASE), 'Radiyallahu Anh'),
    (re.compile(r"\bHz\.", re.IGNORECASE), 'Hazreti'),
    # replace `b.` token with `Bin` when it's a separate token (word boundary)
    (re.compile(r"\bb\.\b"), 'Bin'),
]

changed = 0
samples = []
for rec in records:
    text = rec.get('text_tr', '')
    new_text = text
    for pat, repl in replacements:
        new_text = pat.sub(repl, new_text)
    if new_text != text:
        rec['text_tr'] = new_text
        changed += 1
        if len(samples) < 10:
            samples.append((rec.get('id'), text, new_text))

if changed == 0:
    print('No replacements needed.')
else:
    print(f'Backing up original to {backup_path}')
    in_path.rename(backup_path)
    print(f'Writing updated file: {in_path}')
    in_path.write_text(json.dumps(obj, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f'Changed records: {changed}')
    print('Sample changes:')
    for s in samples:
        print('---', s[0])
        print('BEFORE:')
        print(s[1])
        print('AFTER:')
        print(s[2])

print('Done')
