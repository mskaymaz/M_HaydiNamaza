import json
import re
import shutil
from datetime import datetime

SRC = 'Besmele/data/daily_panel/publish/hadiths.v1.approved.json'
BACKUP = SRC + '.bak.' + datetime.now().strftime('%Y%m%d%H%M%S')

with open(SRC, 'r', encoding='utf-8') as f:
    data = json.load(f)

shutil.copy2(SRC, BACKUP)
print('Backup created:', BACKUP)

records = data.get('records', [])
changed = []
paren_re = re.compile(r"\s*\(.*?\)\s*$", re.DOTALL)

for rec in records:
    book_ref = rec.get('book_reference_tr', '') or ''
    text_tr = rec.get('text_tr', '') or ''
    original = text_tr

    if book_ref and book_ref in text_tr:
        # remove exact book_ref occurrences
        text_tr = text_tr.replace(book_ref, '')
    else:
        # if ends with a parenthetical, remove it
        new = paren_re.sub('', text_tr)
        if new != text_tr:
            text_tr = new

    # trim trailing blank lines and spaces
    text_tr = text_tr.rstrip('\n').rstrip()

    if text_tr != original:
        rec['text_tr'] = text_tr
        changed.append(rec.get('id'))

with open(SRC, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print('Changed records:', len(changed))
if changed:
    print('\n'.join(changed))
else:
    print('No changes made.')
