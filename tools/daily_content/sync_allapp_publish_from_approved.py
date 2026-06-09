from __future__ import annotations

import argparse
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[2]
LOCAL_APPROVED_ROOT = REPO_ROOT / "assets" / "data" / "daily_content" / "approved"
DEFAULT_ALLAPP_ROOT = REPO_ROOT / "_external" / "AllAppRemote" / "data" / "daily_content" / "v1"


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Sync local approved daily content into AllApp publish v1 files."
    )
    parser.add_argument(
        "--target-root",
        default=str(DEFAULT_ALLAPP_ROOT),
        help="AllApp data/daily_content/v1 root.",
    )
    args = parser.parse_args()

    target_root = Path(args.target_root).resolve()
    publish_root = target_root / "publish"
    publish_root.mkdir(parents=True, exist_ok=True)

    generated_at = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
    content_version = "local-approved-" + datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")

    old_ayah_payload = _read_json(publish_root / "ayahs.v1.approved.json", default={})
    old_hadith_payload = _read_json(publish_root / "hadiths.v1.approved.json", default={})
    local_ayah_payload = _read_json(LOCAL_APPROVED_ROOT / "ayahs.v1.approved.json")
    local_hadith_payload = _read_json(LOCAL_APPROVED_ROOT / "hadiths.v1.approved.json")

    ayah_records = _build_ayah_records(
        local_records=_records(local_ayah_payload),
        old_records=_records(old_ayah_payload),
        generated_at=generated_at,
    )
    hadith_records = _build_hadith_records(
        local_records=_records(local_hadith_payload),
        old_records=_records(old_hadith_payload),
        generated_at=generated_at,
    )

    ayah_payload = {
        "schema_version": "2.0.0",
        "content_version": content_version,
        "type": "ayah",
        "records": ayah_records,
    }
    hadith_payload = {
        "schema_version": "2.0.0",
        "content_version": content_version,
        "type": "hadith",
        "records": hadith_records,
    }

    ayah_path = publish_root / "ayahs.v1.approved.json"
    hadith_path = publish_root / "hadiths.v1.approved.json"
    _write_json(ayah_path, ayah_payload)
    _write_json(hadith_path, hadith_payload)

    manifest = {
        "schema_version": "1.0.0",
        "content_version": content_version,
        "generated_at_utc": generated_at,
        "publish_files": {
            "ayahs": _manifest_file("publish/ayahs.v1.approved.json", ayah_path, len(ayah_records)),
            "hadiths": _manifest_file(
                "publish/hadiths.v1.approved.json",
                hadith_path,
                len(hadith_records),
            ),
        },
        "schedule": {
            "start_date": "2026-05-15",
        },
    }
    _write_json(target_root / "manifest.json", manifest)

    print("allapp publish synced")
    print(f"ayah records: {len(ayah_records)}")
    print(f"hadith records: {len(hadith_records)}")
    print(f"target: {target_root}")


def _build_ayah_records(
    *,
    local_records: list[dict[str, Any]],
    old_records: list[dict[str, Any]],
    generated_at: str,
) -> list[dict[str, Any]]:
    old_by_key = {
        _ayah_key(record): record
        for record in old_records
        if _ayah_key(record) is not None
    }
    output = []
    for record in local_records:
        key = _ayah_key(record)
        old = old_by_key.get(key) if key is not None else None
        ref = _string(record.get("ref")) or _string(record.get("id"))
        output.append(
            {
                "id": _string(record.get("id")) or ref,
                "type": "ayah",
                "surah_name": _string(record.get("surah_name"))
                or _string((old or {}).get("surah_name"))
                or "requires verification",
                "surah_number": _int(record.get("surah_number")),
                "ayah_number": _int(record.get("ayah_number")),
                "text_ar": _string(record.get("ar")),
                "text_tr": _string(record.get("tr")),
                "text_en": _string(record.get("en")),
                "source_ar": _string((old or {}).get("source_ar")) or f"local_approved:{ref}:ar",
                "source_tr": _string((old or {}).get("source_tr")) or f"local_approved:{ref}:tr",
                "source_en": _string((old or {}).get("source_en")) or f"local_approved:{ref}:en",
                "meal_source": _string((old or {}).get("meal_source")) or "local approved payload",
                "source_note": _source_note(old, record, generated_at),
                "topics": _topics(old),
                "status": "approved",
                "durum": _durum(record),
                "priority": _int(record.get("priority"), default=1),
                "approval": _approval(record, generated_at),
            }
        )
    return output


def _build_hadith_records(
    *,
    local_records: list[dict[str, Any]],
    old_records: list[dict[str, Any]],
    generated_at: str,
) -> list[dict[str, Any]]:
    old_by_number = {
        _string(record.get("hadith_number")): record
        for record in old_records
        if _string(record.get("hadith_number"))
    }
    output = []
    for record in local_records:
        hadith_number = _string(record.get("hadith_number"))
        old = old_by_number.get(hadith_number)
        output.append(
            {
                "id": _string(record.get("id")) or f"hadith_{hadith_number}",
                "type": "hadith",
                "collection": _string((old or {}).get("collection")) or "Riyazu's-Salihin",
                "book": _string((old or {}).get("book")) or f"Riyad as-Salihin {hadith_number}",
                "hadith_number": hadith_number,
                "narrator": _string((old or {}).get("narrator")) or "requires verification",
                "text_ar": _string(record.get("ar")),
                "text_tr": _string(record.get("tr")),
                "text_en": _string(record.get("en")),
                "source_ar": _string((old or {}).get("source_ar"))
                or f"local_approved:riyazussalihin/{hadith_number}:ar",
                "source_tr": _string((old or {}).get("source_tr"))
                or f"local_approved:riyazussalihin/{hadith_number}:tr",
                "source_en": _string((old or {}).get("source_en"))
                or f"local_approved:riyazussalihin/{hadith_number}:en",
                "grade": _string((old or {}).get("grade")) or "riyad_as_salihin_selection",
                "source_note": _source_note(old, record, generated_at),
                "topics": _topics(old, fallback="hadis_approved_pool"),
                "status": "approved",
                "durum": _durum(record),
                "priority": _int(record.get("priority"), default=1),
                "book_reference_tr": _string(record.get("book_reference_tr")),
                "book_reference_en": _string(record.get("book_reference_en")),
                "approval": _approval(record, generated_at),
            }
        )
    return output


def _source_note(old: dict[str, Any] | None, record: dict[str, Any], generated_at: str) -> str:
    existing = _string((old or {}).get("source_note"))
    if existing:
        return existing
    approved_at = _string(record.get("approvedAt"))
    suffix = f"approved_at={approved_at}" if approved_at else f"synced_at={generated_at}"
    return f"local approved payload; {suffix}"


def _approval(record: dict[str, Any], generated_at: str) -> dict[str, str]:
    return {
        "approved_by": "local_review_tool",
        "approved_at": _string(record.get("approvedAt")) or generated_at,
        "review_note": "Synced from local approved payload.",
    }


def _topics(old: dict[str, Any] | None, fallback: str = "ayah_approved_pool") -> list[str]:
    topics = (old or {}).get("topics")
    if isinstance(topics, list):
        cleaned = [_string(item) for item in topics]
        cleaned = [item for item in cleaned if item]
        if cleaned:
            return cleaned
    return [fallback]


def _durum(record: dict[str, Any]) -> str:
    return _string(record.get("durum")) or "yayina_hazir"


def _ayah_key(record: dict[str, Any]) -> tuple[int, int] | None:
    surah = _int(record.get("surah_number"))
    ayah = _int(record.get("ayah_number"))
    if surah is None or ayah is None:
        return None
    return (surah, ayah)


def _records(payload: Any) -> list[dict[str, Any]]:
    if not isinstance(payload, dict):
        return []
    records = payload.get("records")
    if not isinstance(records, list):
        return []
    return [dict(record) for record in records if isinstance(record, dict)]


def _manifest_file(path: str, file_path: Path, record_count: int) -> dict[str, Any]:
    return {
        "path": path,
        "sha256": _sha256(file_path),
        "bytes": file_path.stat().st_size,
        "record_count": record_count,
    }


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _read_json(path: Path, default: Any | None = None) -> Any:
    if not path.exists():
        if default is not None:
            return default
        raise FileNotFoundError(path)
    return json.loads(path.read_text(encoding="utf-8-sig"))


def _write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def _string(value: Any) -> str:
    if value is None:
        return ""
    return str(value).strip()


def _int(value: Any, default: int | None = None) -> int | None:
    if isinstance(value, bool):
        return default
    if isinstance(value, int):
        return value
    if isinstance(value, float):
        return int(value)
    if isinstance(value, str):
        try:
            return int(value.strip())
        except ValueError:
            return default
    return default


if __name__ == "__main__":
    main()
