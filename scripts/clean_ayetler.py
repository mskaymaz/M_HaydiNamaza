#!/usr/bin/env python3
"""
Clean duplicate sure/ayet entries in docs/Ayetler_Edit.docx.

Behavior:
- Finds tokens like `sss/aaa` (digits slash digits) in paragraphs.
- Keeps the first occurrence of each unique `sss/aaa` (normalized by removing spaces).
- Removes subsequent duplicate tokens from the text.
- Writes cleaned document to `docs/Ayetler_Edit.deduped.docx`.

Usage:
    python scripts/clean_ayetler.py [input_docx] [--inplace]

Dependencies:
    pip install python-docx
"""
from pathlib import Path
import re
import sys
from docx import Document


PAT = re.compile(r"(\d+\s*/\s*\d+)")


def normalize(token: str) -> str:
    return re.sub(r"\s+", "", token)


def clean_paragraph_text(text: str, seen: set) -> str:
    if not text:
        return text
    parts = []
    last = 0
    for m in PAT.finditer(text):
        token = m.group(1)
        norm = normalize(token)
        # always append text between last and match start
        parts.append(text[last:m.start()])
        if norm in seen:
            # skip the duplicate token (remove it)
            last = m.end()
            continue
        else:
            seen.add(norm)
            parts.append(text[m.start():m.end()])
            last = m.end()
    parts.append(text[last:])
    cleaned = ''.join(parts)
    # collapse multiple spaces produced by removals
    cleaned = re.sub(r"[ \t]{2,}", " ", cleaned).strip()
    # remove leading/trailing separators if they remain (commas, semicolons)
    cleaned = re.sub(r"^[,;:\-\s]+", "", cleaned)
    cleaned = re.sub(r"[,;:\-\s]+$", "", cleaned)
    return cleaned


def process_document(in_path: Path, out_path: Path):
    doc = Document(in_path)
    new_doc = Document()
    seen = set()

    for para in doc.paragraphs:
        text = para.text
        if not text.strip():
            new_doc.add_paragraph("")
            continue
        if not PAT.search(text):
            new_doc.add_paragraph(text)
            continue
        cleaned = clean_paragraph_text(text, seen)
        if cleaned:
            new_doc.add_paragraph(cleaned)

    # Also attempt to copy tables (simple approach: convert cell text similarly)
    # If doc has tables, add them at the end as paragraphs with cleaned cell texts.
    if doc.tables:
        new_doc.add_paragraph('')
        new_doc.add_paragraph('--- Cleaned table contents ---')
        for table in doc.tables:
            for row in table.rows:
                cells_text = []
                for cell in row.cells:
                    t = cell.text
                    if PAT.search(t):
                        t = clean_paragraph_text(t, seen)
                    cells_text.append(t.strip())
                new_doc.add_paragraph(' | '.join(cells_text))

    new_doc.save(out_path)


def main():
    if len(sys.argv) >= 2:
        in_file = Path(sys.argv[1])
    else:
        in_file = Path('docs') / 'Ayetler_Edit.docx'

    if not in_file.exists():
        print(f"Input file not found: {in_file}")
        sys.exit(2)

    out_file = in_file.with_name(in_file.stem + '.deduped.docx')

    inplace = '--inplace' in sys.argv or '-i' in sys.argv
    if inplace:
        backup = in_file.with_name(in_file.stem + '.backup.docx')
        in_file.rename(backup)
        out_file = in_file
        in_file = backup

    print(f"Processing {in_file} -> {out_file}")
    process_document(in_file, out_file)
    print('Done.')


if __name__ == '__main__':
    main()
