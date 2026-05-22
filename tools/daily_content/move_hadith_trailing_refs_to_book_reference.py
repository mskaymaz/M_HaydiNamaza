#!/usr/bin/env python3
"""Move trailing TR reference brackets into book_reference_tr for all hadith records.

Default target:
  Besmele/data/daily_panel/publish/hadisler.json

What it does:
- For each hadith record, if `text_tr` ends with a reference-like bracket group
  ( (...) or [...] ) it moves that tail into `book_reference_tr`.
- Keeps existing `book_reference_tr` and appends new refs with '; ' (dedup).
- Creates a one-time backup next to the input file: `.bak.YYYYMMDD_HHMMSS`.

Usage:
  py tools/daily_content/move_hadith_trailing_refs_to_book_reference.py --dry-run
  py tools/daily_content/move_hadith_trailing_refs_to_book_reference.py --write
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
from datetime import datetime
from pathlib import Path
from typing import Any


def _atomic_json_write(path: Path, data: Any) -> None:
    tmp = path.with_suffix(path.suffix + ".tmp")
    with tmp.open("w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")
    tmp.replace(path)


def _ensure_backup(path: Path) -> Path:
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = path.with_suffix(path.suffix + f".bak.{ts}")
    shutil.copy2(path, backup_path)
    return backup_path


def _extract_trailing_book_ref(text_tr: str, existing_ref: str) -> tuple[str, str, list[str]]:
    work = str(text_tr or "")
    refs: list[str] = []
    if str(existing_ref or "").strip():
        refs.append(str(existing_ref).strip())

    ref_cue = (
        "Buhar|Bukhari|Müslim|Muslim|Tirmiz|Tirmizî|Nesai|Nesa'i|"
        "Ebû|Ebu|Dâv|Dav|Dawud|Mâce|Mace|İM|IM|Ahmed|Darimi|Dârim|"
        "Bkz|bkz|B\\d|M\\d|T\\d|D\\d"
    )

    moved_tails: list[str] = []
    while True:
        m = re.match(
            r'(?s)^(.*?)(\s*([\(\[])([^()\[\]]*)([\)\]])\s*[\.\!؟،»"]?\s*)$',
            work,
        )
        if not m:
            break
        inside = (m.group(4) or "").strip()
        if not inside:
            break
        if not re.search(ref_cue, inside):
            break

        tail = (m.group(2) or "").strip()
        tail = re.sub(r'[\.\!؟،»"]\s*$', "", tail).strip()
        if tail.startswith("[") and tail.endswith("]"):
            tail = "(" + tail[1:-1].strip() + ")"

        if tail:
            moved_tails.append(tail)
            if tail not in refs:
                refs.append(tail)

        work = (m.group(1) or "").rstrip()

    return work, "; ".join(refs).strip(), moved_tails


def main() -> int:
    repo_root = Path(__file__).resolve().parents[2]
    default_path = repo_root / "Besmele" / "data" / "daily_panel" / "publish" / "hadisler.json"

    parser = argparse.ArgumentParser()
    parser.add_argument("--input", default=str(default_path), help="Path to hadisler.json")
    parser.add_argument("--write", action="store_true", help="Write changes to input JSON")
    parser.add_argument("--dry-run", action="store_true", help="Do not write; just print stats")
    parser.add_argument("--max-samples", type=int, default=10, help="How many sample IDs to print")
    args = parser.parse_args()

    path = Path(args.input).resolve()
    if not path.exists():
        raise FileNotFoundError(path)

    with path.open("r", encoding="utf-8-sig") as f:
        payload = json.load(f)

    if not isinstance(payload, dict) or not isinstance(payload.get("records"), list):
        raise ValueError("Expected JSON object with records[]")

    records: list[dict[str, Any]] = payload["records"]

    changed = 0
    changed_text = 0
    changed_ref = 0
    sample_ids: list[str] = []

    for rec in records:
        if str(rec.get("type", "")).strip().lower() != "hadith":
            continue
        original_tr = str(rec.get("text_tr", "") or "")
        original_ref = str(rec.get("book_reference_tr", "") or "")

        new_tr, new_ref, moved_tails = _extract_trailing_book_ref(original_tr, original_ref)
        if not moved_tails:
            continue

        # Apply changes
        rec["text_tr"] = new_tr
        rec["book_reference_tr"] = new_ref

        changed += 1
        if new_tr != original_tr:
            changed_text += 1
        if new_ref != original_ref:
            changed_ref += 1
        if len(sample_ids) < int(args.max_samples):
            sample_ids.append(str(rec.get("id", "-")))

    print(f"Processed records: {len(records)}")
    print(f"Hadith changed: {changed} (text_tr changed: {changed_text}, book_reference_tr changed: {changed_ref})")
    if sample_ids:
        print("Sample IDs:")
        for sid in sample_ids:
            print(f"- {sid}")

    if args.dry_run and args.write:
        raise ValueError("Use either --dry-run or --write (not both).")

    if args.write:
        backup = _ensure_backup(path)
        _atomic_json_write(path, payload)
        print(f"Wrote: {path}")
        print(f"Backup: {backup}")
    else:
        print("Dry-run only; no files written.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
