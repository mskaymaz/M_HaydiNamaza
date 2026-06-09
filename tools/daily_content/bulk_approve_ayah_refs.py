from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[2]
CONTENT_TOOL_ROOT = REPO_ROOT / "tools" / "content_review"
if str(CONTENT_TOOL_ROOT) not in sys.path:
    sys.path.insert(0, str(CONTENT_TOOL_ROOT))

from core.exporters import apply_record_to_raw, to_approved_record  # noqa: E402
from core.fetchers.ayah_fetcher import AyahFetcher  # noqa: E402
from core.models import AyahRecord, DuplicateCheckResult  # noqa: E402
from core.reference_parser import normalize_reference  # noqa: E402
from core.text_normalizer import normalize_record_texts  # noqa: E402
from core.validators import validate_approved_record, validate_record  # noqa: E402


APPROVED_PATH = REPO_ROOT / "assets" / "data" / "daily_content" / "approved" / "ayahs.v1.approved.json"
ARCHIVE_PATH = REPO_ROOT / "assets" / "data" / "daily_content" / "archive" / "ayahs.pending_review.v1.json"
BACKUP_ROOT = CONTENT_TOOL_ROOT / "backups"
ONAY_STATE_PATH = CONTENT_TOOL_ROOT / "onay_state.json"


def main() -> None:
    parser = argparse.ArgumentParser(description="Bulk approve ayah refs from local Tanzil sources.")
    parser.add_argument("--refs", default="", help="Whitespace/comma separated ayah refs.")
    parser.add_argument("--refs-file", default="", help="Text file containing ayah refs.")
    parser.add_argument("--dry-run", action="store_true", help="Only report what would change.")
    args = parser.parse_args()

    raw_refs = args.refs
    if args.refs_file:
        raw_refs = Path(args.refs_file).read_text(encoding="utf-8-sig")
    if not raw_refs.strip():
        raise SystemExit("--refs veya --refs-file zorunlu.")
    refs = _unique_refs(raw_refs)
    approved_payload = _read_json(APPROVED_PATH)
    archive_payload = _read_json(ARCHIVE_PATH)

    approved_rows = _records(approved_payload)
    archive_rows = _records(archive_payload)
    approved_spans = [_span_from_row(row) for row in approved_rows]
    approved_spans = [span for span in approved_spans if span is not None]
    archive_by_ref = {str(row.get("ref") or "").strip(): index for index, row in enumerate(archive_rows)}
    onay_processed = _onay_processed_keys("ayah")

    fetcher = AyahFetcher()
    added: list[str] = []
    already: list[str] = []
    skipped_onay: list[str] = []
    missing: list[str] = []
    records: list[AyahRecord] = []

    now = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
    for ref in refs:
        normalized = normalize_reference("ayah", ref)
        normalized_ref = str(normalized["ref"])
        if normalized_ref in onay_processed:
            skipped_onay.append(normalized_ref)
            continue
        if _covered_by_spans(normalized_ref, approved_spans):
            already.append(normalized_ref)
            continue

        result = fetcher.fetch_reference(normalized)
        if not result.success:
            missing.append(normalized_ref)
            continue

        ar, tr, en = normalize_record_texts(result.ar, result.tr, result.en)
        raw_record = dict(result.extra.get("raw_record") or {})
        record = AyahRecord(
            id=normalized_ref,
            kind="ayah",
            ref=normalized_ref,
            ar=ar,
            tr=tr,
            en=en,
            status="approved",
            priority=1,
            notes="bulk approved from local Tanzil source",
            source_info=result.source_info,
            duplicate_info=DuplicateCheckResult(),
            review_history=[
                {
                    "at": now,
                    "status": "approved",
                    "priority": 1,
                    "notes": "bulk approved from local Tanzil source",
                }
            ],
            created_at=now,
            updated_at=now,
            approved_at=now,
            raw=raw_record,
            surah_number=int(normalized["surah_number"]),
            ayah_number=int(normalized["ayah_start"]),
            ayah_end_number=int(normalized["ayah_end"]),
            surah_name=str(normalized["surah_name"]),
        )
        validate_record(record)
        validate_approved_record(to_approved_record(record))
        records.append(record)
        added.append(normalized_ref)

    print(
        f"input={len(refs)} already={len(already)} "
        f"onay_skip={len(skipped_onay)} add={len(added)} missing={len(missing)}"
    )
    if already:
        print("already:", _compact(already))
    if skipped_onay:
        print("onay_skip:", _compact(skipped_onay))
    if missing:
        print("missing:", _compact(missing))

    if args.dry_run:
        return
    if missing:
        raise SystemExit("Eksik ayet varken yazma durduruldu.")

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


def _upsert_approved_row(rows: list[dict[str, Any]], record: AyahRecord) -> None:
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
        "surah_number": approved.surah_number,
        "surah_name": approved.surah_name,
        "ayah_number": approved.ayah_number,
        "ayah_end_number": approved.ayah_end_number,
    }
    for index, current in enumerate(rows):
        if str(current.get("id") or "").strip() == approved.id:
            rows[index] = row
            return
        if str(current.get("ref") or "").strip() == approved.ref:
            rows[index] = row
            return
    rows.append(row)


def _unique_refs(raw: str) -> list[str]:
    refs: list[str] = []
    for part in raw.replace(",", " ").split():
        ref = str(normalize_reference("ayah", part)["ref"])
        if ref not in refs:
            refs.append(ref)
    return refs


def _covered_by_spans(ref: str, spans: list[tuple[int, int, int]]) -> bool:
    parsed = _parse_ref(ref)
    if parsed is None:
        return False
    surah, start, end = parsed
    return any(span_surah == surah and span_start <= start and end <= span_end for span_surah, span_start, span_end in spans)


def _span_from_row(row: dict[str, Any]) -> tuple[int, int, int] | None:
    by_ref = _parse_ref(str(row.get("ref") or row.get("id") or ""))
    if by_ref is not None:
        return by_ref
    surah = _safe_int(row.get("surah_number") or row.get("surah"))
    start = _safe_int(row.get("ayah_number") or row.get("ayahStart"))
    end = _safe_int(row.get("ayah_end_number") or row.get("ayahEnd")) or start
    if surah is None or start is None or end is None:
        return None
    return surah, start, end


def _parse_ref(ref: str) -> tuple[int, int, int] | None:
    match = re.fullmatch(r"0*(\d{1,3})/0*(\d{1,3})(?:-0*(\d{1,3}))?", str(ref or "").strip())
    if not match:
        return None
    return int(match.group(1)), int(match.group(2)), int(match.group(3) or match.group(2))


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


def _write_json(path: Path, payload: dict[str, Any]) -> None:
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def _backup(path: Path, stamp: str) -> None:
    BACKUP_ROOT.mkdir(parents=True, exist_ok=True)
    target = BACKUP_ROOT / f"{path.name}.{stamp}.bulk.bak"
    shutil.copy2(path, target)


def _safe_int(value: Any) -> int | None:
    try:
        if value is None or value == "":
            return None
        return int(value)
    except (TypeError, ValueError):
        return None


def _compact(values: list[str]) -> str:
    text = " ".join(values)
    return text if len(text) <= 240 else text[:240].rstrip() + " ..."


if __name__ == "__main__":
    main()
