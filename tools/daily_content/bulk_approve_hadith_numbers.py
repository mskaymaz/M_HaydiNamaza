from __future__ import annotations

import argparse
import json
import shutil
import sys
from dataclasses import replace
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[2]
CONTENT_TOOL_ROOT = REPO_ROOT / "tools" / "content_review"
if str(CONTENT_TOOL_ROOT) not in sys.path:
    sys.path.insert(0, str(CONTENT_TOOL_ROOT))

from core.exporters import apply_record_to_raw, to_approved_record  # noqa: E402
from core.fetchers.hadith_fetcher import HadithFetcher  # noqa: E402
from core.models import DuplicateCheckResult, HadithRecord  # noqa: E402
from core.text_extractors import extract_trailing_reference  # noqa: E402
from core.text_normalizer import normalize_record_texts  # noqa: E402
from core.validators import validate_approved_record, validate_record  # noqa: E402


APPROVED_PATH = REPO_ROOT / "assets" / "data" / "daily_content" / "approved" / "hadiths.v1.approved.json"
ARCHIVE_PATH = REPO_ROOT / "assets" / "data" / "daily_content" / "archive" / "hadiths.pending_review.v1.json"
BACKUP_ROOT = CONTENT_TOOL_ROOT / "backups"
ONAY_STATE_PATH = CONTENT_TOOL_ROOT / "onay_state.json"


def main() -> None:
    parser = argparse.ArgumentParser(description="Bulk approve Riyazus Salihin hadith numbers from local seeds.")
    parser.add_argument("--numbers", required=True, help="Whitespace/comma separated hadith numbers.")
    parser.add_argument("--dry-run", action="store_true", help="Only report what would change.")
    args = parser.parse_args()

    numbers = _unique_numbers(args.numbers)
    approved_payload = _read_json(APPROVED_PATH)
    archive_payload = _read_json(ARCHIVE_PATH)

    approved_rows = _records(approved_payload)
    archive_rows = _records(archive_payload)
    approved_numbers = _approved_numbers(approved_rows)
    archive_by_ref = {str(row.get("ref") or "").strip(): index for index, row in enumerate(archive_rows)}
    onay_processed = _onay_processed_keys("hadith")

    fetcher = HadithFetcher()
    added: list[int] = []
    already: list[int] = []
    skipped_onay: list[int] = []
    missing: list[int] = []
    nearby: list[int] = []
    records: list[HadithRecord] = []

    now = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
    for number in numbers:
        if _hadith_processed(number, onay_processed):
            skipped_onay.append(number)
            continue
        if number in approved_numbers:
            already.append(number)
            continue
        result = fetcher.fetch(number)
        if result.status_label == "local_hadith_nearby":
            nearby.append(number)
            continue
        if not result.success or result.status_label != "local_hadith_exact":
            missing.append(number)
            continue

        ar, tr, en = normalize_record_texts(result.ar, result.tr, result.en)
        tr, book_ref_tr = extract_trailing_reference(tr)
        en, book_ref_en = extract_trailing_reference(en)
        record = HadithRecord(
            id=f"hadith_{number:06d}",
            kind="hadith",
            ref=f"riyazussalihin/{number}",
            ar=ar,
            tr=tr,
            en=en,
            status="approved",
            priority=1,
            notes="bulk approved from local seed",
            source_info=result.source_info,
            duplicate_info=DuplicateCheckResult(),
            review_history=[
                {
                    "at": now,
                    "status": "approved",
                    "priority": 1,
                    "notes": "bulk approved from local seed",
                }
            ],
            created_at=now,
            updated_at=now,
            approved_at=now,
            raw=dict(result.extra.get("raw_record") or {}),
            hadith_number=number,
            book_reference_tr=book_ref_tr,
            book_reference_en=book_ref_en,
        )
        validate_record(record)
        validate_approved_record(to_approved_record(record))
        records.append(record)
        added.append(number)

    print(
        f"input={len(numbers)} already={len(already)} "
        f"onay_skip={len(skipped_onay)} add={len(added)} nearby={len(nearby)} missing={len(missing)}"
    )
    if already:
        print("already:", _compact(already))
    if skipped_onay:
        print("onay_skip:", _compact(skipped_onay))
    if nearby:
        print("nearby_skip:", _compact(nearby))
    if missing:
        print("missing_skip:", _compact(missing))

    if args.dry_run:
        return
    if nearby or missing:
        raise SystemExit("Eksik veya yakin eslesme varken yazma durduruldu.")

    for record in records:
        _upsert_approved_row(approved_rows, record)
        raw = apply_record_to_raw(record)
        archive_index = archive_by_ref.get(record.ref)
        if archive_index is None:
            archive_by_ref[record.ref] = len(archive_rows)
            archive_rows.append(raw)
        else:
            archive_rows[archive_index] = raw

    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    _backup(APPROVED_PATH, stamp)
    _backup(ARCHIVE_PATH, stamp)

    approved_payload["records"] = approved_rows
    approved_payload["content_version"] = f"bulk-approved-{stamp}"
    archive_root_key = "items" if isinstance(archive_payload.get("items"), list) else "records"
    archive_payload[archive_root_key] = archive_rows
    metadata = archive_payload.get("metadata")
    if isinstance(metadata, dict):
        metadata["totalItems"] = len(archive_rows)
        metadata["updatedAt"] = now

    _write_json(APPROVED_PATH, approved_payload)
    _write_json(ARCHIVE_PATH, archive_payload)
    print(f"written approved_total={len(approved_rows)} archive_total={len(archive_rows)}")


def _upsert_approved_row(rows: list[dict[str, Any]], record: HadithRecord) -> None:
    approved = to_approved_record(record)
    row = {
        "id": approved.id,
        "kind": approved.kind,
        "ref": approved.ref,
        "ar": approved.ar,
        "tr": approved.tr,
        "en": approved.en,
        "priority": approved.priority,
        "durum": "yayina_hazir",
        "approvedAt": approved.approved_at,
        "hadith_number": approved.hadith_number,
        "book_reference_tr": approved.book_reference_tr,
        "book_reference_en": approved.book_reference_en,
    }
    for index, current in enumerate(rows):
        if str(current.get("id") or "").strip() == approved.id:
            rows[index] = row
            return
        if str(current.get("ref") or "").strip() == approved.ref:
            rows[index] = row
            return
    rows.append(row)


def _unique_numbers(raw: str) -> list[int]:
    numbers: list[int] = []
    for part in raw.replace(",", " ").split():
        number = int(part.strip())
        if number not in numbers:
            numbers.append(number)
    return numbers


def _approved_numbers(rows: list[dict[str, Any]]) -> set[int]:
    numbers: set[int] = set()
    for row in rows:
        value = row.get("hadith_number")
        try:
            numbers.add(int(value))
        except (TypeError, ValueError):
            pass
    return numbers


def _records(payload: dict[str, Any]) -> list[dict[str, Any]]:
    for key in ("records", "items"):
        rows = payload.get(key)
        if isinstance(rows, list):
            return [dict(row) for row in rows if isinstance(row, dict)]
    return []


def _read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def _onay_processed_keys(kind: str) -> set[str]:
    if not ONAY_STATE_PATH.exists():
        return set()
    payload = json.loads(ONAY_STATE_PATH.read_text(encoding="utf-8-sig"))
    processed = payload.get("processed") if isinstance(payload, dict) else {}
    kind_map = processed.get(kind) if isinstance(processed, dict) else {}
    if not isinstance(kind_map, dict):
        return set()
    return {str(key).strip() for key in kind_map if str(key).strip()}


def _hadith_processed(number: int, processed: set[str]) -> bool:
    return any(
        key in processed
        for key in (
            str(number),
            f"hadith_{number:06d}",
            f"riyazussalihin/{number}",
        )
    )


def _write_json(path: Path, payload: dict[str, Any]) -> None:
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def _backup(path: Path, stamp: str) -> None:
    BACKUP_ROOT.mkdir(parents=True, exist_ok=True)
    target = BACKUP_ROOT / f"{path.name}.{stamp}.bulk.bak"
    shutil.copy2(path, target)


def _compact(numbers: list[int]) -> str:
    text = " ".join(str(number) for number in numbers)
    return text if len(text) <= 240 else text[:240].rstrip() + " ..."


if __name__ == "__main__":
    main()
