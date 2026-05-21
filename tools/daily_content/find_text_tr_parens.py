import json, re
SRC = 'Besmele/data/daily_panel/publish/hadiths.v1.approved.json'
pattern = re.compile(r"\([A-Za-zÇĞİŞÜÖçğışüö][0-9]|\(T|\(M|\(B")
with open(SRC, 'r', encoding='utf-8') as f:
    data = json.load(f)

found = []
for rec in data.get('records', []):
    text = rec.get('text_tr','')
    if '(' in text:
        # crude filter: parentheses containing a digit (likely our refs)
        if re.search(r"\(.*?\d+.*?\)", text):
            found.append((rec.get('id'), text.strip()[:120].replace('\n',' ')))

print('Found', len(found), 'records with parenthetical digits in text_tr')
for fid, excerpt in found[:200]:
    print(fid)
    print('  ', excerpt)
