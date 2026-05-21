import json, re, shutil, datetime
SRC = 'Besmele/data/daily_panel/publish/hadiths.v1.approved.json'
now = datetime.datetime.now().strftime('%Y%m%d%H%M%S')
BACKUP = SRC + '.bak.' + now

paren_with_digit_re = re.compile(r"\(([^)]*?\d[^)]*)\)")
paren_any_re = re.compile(r"\(([^)]+)\)")

with open(SRC, 'r', encoding='utf-8') as f:
    data = json.load(f)

records = data.get('records', [])
changed = []
for rec in records:
    text = rec.get('text_tr', '')
    book_ref = (rec.get('book_reference_tr') or '').strip()

    # Find parentheticals containing digits (likely book refs)
    matches = paren_with_digit_re.findall(text)

    # Fallback: if none with digits, consider parentheticals that start with common letters (B,T,M,D)
    if not matches:
        for m in paren_any_re.findall(text):
            if re.match(r"^[BTMD]\d", m) or re.search(r"\b(Buhârî|Buhari|Müslim|Tirmiz|Tirmizî|Tirmizi|B)\b", m, re.I):
                matches.append(m)
                break

    if matches:
        # prefer first match
        candidate = matches[0].strip()
        # ensure parentheses around candidate
        candidate_paren = '(' + candidate + ')'
        modified = False

        # If book_reference_tr empty, set it. If not empty but doesn't contain candidate, append on new line.
        if not book_ref:
            rec['book_reference_tr'] = candidate_paren
            modified = True
        else:
            if candidate not in book_ref:
                # append, keep existing value and add the candidate separated by '; '
                rec['book_reference_tr'] = book_ref + '; ' + candidate_paren
                modified = True

        # Remove ALL occurrences of the matched parentheticals from text_tr
        new_text = text
        for m in set(matches):
            new_text = re.sub(r"\(\s*" + re.escape(m) + r"\s*\)", '', new_text)
        # Also remove any leftover doubled spaces and trailing punctuation/whitespace
        new_text = re.sub(r"[ \t]+", ' ', new_text).strip()
        new_text = re.sub(r"[,;:\-–—]+\s*$", '', new_text).strip()

        if new_text != text:
            rec['text_tr'] = new_text
            modified = True

        if modified:
            changed.append(rec.get('id'))

# Write backup and save
if changed:
    shutil.copy2(SRC, BACKUP)
    with open(SRC, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

print('Backup created:', BACKUP if changed else 'No changes, no backup created')
print('Changed records:', len(changed))
for cid in changed:
    print(cid)
