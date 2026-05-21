import json
import re
from pathlib import Path

in_path = Path(r"Besmele/data/daily_panel/publish/hadiths.v1.approved.json")
backup_path = in_path.with_suffix('.approved.json.bak')
out_path = in_path

print(f"Loading {in_path}")
raw = in_path.read_text(encoding='utf-8')
obj = json.loads(raw)
records = obj.get('records', [])

pattern = re.compile(r"\n\(([^)]+)\)")
changed = 0
samples = []
for rec in records:
    text_tr = rec.get('text_tr', '')
    m = pattern.search(text_tr)
    if m:
        note = '(' + m.group(1).strip() + ')'
        # remove the matched substring
        new_text = text_tr[:m.start()] + text_tr[m.end():]
        # normalize whitespace
        new_text = new_text.rstrip('\n').rstrip()
        rec['text_tr'] = new_text
        # store to new field; don't overwrite existing if present
        if not rec.get('book_reference_tr'):
            rec['book_reference_tr'] = note
        else:
            rec['book_reference_tr'] = rec['book_reference_tr'] + ' ' + note
        changed += 1
        if len(samples) < 5:
            samples.append((rec.get('id'), note))

if changed == 0:
    print('No changes detected (no matches). Exiting.')
else:
    # backup original
    print(f"Backing up original to {backup_path}")
    in_path.rename(backup_path)
    # write new
    print(f"Writing updated JSON to {out_path}")
    out_path.write_text(json.dumps(obj, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f"Changed records: {changed}")
    print('Sample changes:')
    for s in samples:
        print('  ', s)

print('Done')
