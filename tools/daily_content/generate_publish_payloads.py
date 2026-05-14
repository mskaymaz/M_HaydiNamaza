#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import random
import re
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = REPO_ROOT / "Besmele" / "data" / "daily_panel"
PUBLISH_DIR = DATA_DIR / "publish"
ARCHIVE_ROOT = DATA_DIR / "archive" / "base_release_2026-05-14"
ARCHIVE_DIR = ARCHIVE_ROOT / "publish_generation"
ASSET_DIR = REPO_ROOT / "assets" / "data" / "daily_content" / "approved"
BASE_ARCHIVE = ARCHIVE_ROOT / "legacy_files"

HADITH_TR_SOURCE = BASE_ARCHIVE / "hadiths_draft_DiyanetUnified_v2.json"
HADITH_AR_EN_SOURCE = BASE_ARCHIVE / "hadiths_draft.json"
AYAH_TR_AR_SOURCE = BASE_ARCHIVE / "ayahs_draft_Edit.json"
AYAH_EN_SOURCE = BASE_ARCHIVE / "ayahs_draft.json"

HADITH_PUBLISH = PUBLISH_DIR / "hadiths.v1.approved.json"
AYAH_PUBLISH = PUBLISH_DIR / "ayahs.v1.approved.json"
HADITH_ASSET = ASSET_DIR / "hadiths.v1.approved.json"
AYAH_ASSET = ASSET_DIR / "ayahs.v1.approved.json"
SEQUENCE_PUBLISH = PUBLISH_DIR / "sequence.v1.json"
SEQUENCE_ASSET = ASSET_DIR / "sequence.v1.json"
MANIFEST = ARCHIVE_DIR / "publish_manifest.json"

SEQUENCE_START_DATE = "2026-05-15"
HADITH_TR_MAX_CHARS = 300
MOJIBAKE_MARKERS = (
    "Ãƒ",
    "Ã„",
    "Ã…",
    "Ã¢â‚¬â„¢",
    "Ã¢â‚¬Å“",
    "Ã¢â‚¬Â",
    "Ã¢â‚¬â€œ",
    "Ã¢â‚¬â€",
    "Ø",
    "Ù",
    "Û",
)
ARABIC_RE = re.compile(r"[\u0600-\u06FF]")
CP1252_EXTRA_TO_BYTE = {
    0x20AC: 0x80,
    0x201A: 0x82,
    0x0192: 0x83,
    0x201E: 0x84,
    0x2026: 0x85,
    0x2020: 0x86,
    0x2021: 0x87,
    0x02C6: 0x88,
    0x2030: 0x89,
    0x0160: 0x8A,
    0x2039: 0x8B,
    0x0152: 0x8C,
    0x017D: 0x8E,
    0x2018: 0x91,
    0x2019: 0x92,
    0x201C: 0x93,
    0x201D: 0x94,
    0x2022: 0x95,
    0x2013: 0x96,
    0x2014: 0x97,
    0x02DC: 0x98,
    0x2122: 0x99,
    0x0161: 0x9A,
    0x203A: 0x9B,
    0x0153: 0x9C,
    0x017E: 0x9E,
    0x0178: 0x9F,
}


@dataclass
class FileStat:
    path: Path
    sha256: str
    size: int


def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8-sig") as f:
        return json.load(f)


def save_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")


def file_stat(path: Path) -> FileStat:
    raw = path.read_bytes()
    return FileStat(path=path, sha256=hashlib.sha256(raw).hexdigest(), size=len(raw))


def mojibake_score(text: str) -> int:
    return sum(text.count(marker) for marker in MOJIBAKE_MARKERS)


def cp1252_fixes(text: str) -> str:
    replacements = {
        "Ã¢â‚¬â„¢": "’",
        "Ã¢â‚¬Å“": "“",
        "Ã¢â‚¬Â": "”",
        "Ã¢â‚¬â€œ": "–",
        "Ã¢â‚¬â€": "—",
        "Ã¢â‚¬Â¦": "…",
    }
    out = text
    for old, new in replacements.items():
        out = out.replace(old, new)
    return out


def decode_single_byte_utf8_mojibake(text: str) -> str:
    byte_stream = bytearray()
    for ch in text:
        code = ord(ch)
        if code <= 0xFF:
            byte_stream.append(code)
            continue
        mapped = CP1252_EXTRA_TO_BYTE.get(code)
        if mapped is None:
            return text
        byte_stream.append(mapped)
    try:
        return byte_stream.decode("utf-8")
    except UnicodeError:
        return text


def maybe_fix_mojibake(text: str) -> str:
    if not text:
        return text
    best = cp1252_fixes(decode_single_byte_utf8_mojibake(text))
    best_score = mojibake_score(best)
    current = best
    for _ in range(3):
        improved = False
        for source_encoding in ("latin-1", "cp1252"):
            try:
                candidate = current.encode(source_encoding).decode("utf-8")
            except UnicodeError:
                continue
            candidate = cp1252_fixes(candidate)
            score = mojibake_score(candidate)
            if score < best_score:
                best = candidate
                best_score = score
                current = candidate
                improved = True
        if not improved:
            break
    return best


def strip_known_trailing_artifacts(text: str) -> str:
    out = text
    for artifact in ("\n??Â«", "\n??«", "??Â«", "??«"):
        if out.endswith(artifact):
            out = out[: -len(artifact)]
    return out


def clean_text(value: Any) -> str:
    if not isinstance(value, str):
        return ""
    return strip_known_trailing_artifacts(maybe_fix_mojibake(value)).strip()


def list_to_map_by_id(rows: list[dict[str, Any]]) -> dict[str, dict[str, Any]]:
    out: dict[str, dict[str, Any]] = {}
    for row in rows:
        row_id = clean_text(row.get("id"))
        if not row_id:
            continue
        out[row_id] = row
    return out


def build_hadith_records(
    hadith_tr_records: list[dict[str, Any]],
    hadith_ar_en_map: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    for row in hadith_tr_records:
        row_id = clean_text(row.get("id"))
        if not row_id:
            continue
        ref = hadith_ar_en_map.get(row_id)
        if not ref:
            continue

        text_tr = clean_text(row.get("text_tr")) or clean_text(row.get("text"))
        if not text_tr:
            continue
        if len(text_tr) > HADITH_TR_MAX_CHARS:
            continue

        text_ar = clean_text(ref.get("text_ar"))
        text_en = clean_text(ref.get("text_en"))
        sources = ref.get("sources", {}) if isinstance(ref.get("sources"), dict) else {}
        source_ar = clean_text(sources.get("arabic"))
        source_en = clean_text(sources.get("english"))
        source_tr = clean_text(row.get("source_note"))

        if not (text_ar and text_tr and text_en and source_ar and source_tr and source_en):
            continue

        topics = row.get("topics", [])
        if not isinstance(topics, list):
            topics = []
        clean_topics = [clean_text(t) for t in topics if clean_text(t)]
        if not clean_topics:
            clean_topics = ["hadis_draft_pool"]

        record = {
            "id": row_id,
            "type": "hadith",
            "collection": clean_text(row.get("collection")),
            "book": clean_text(row.get("book")),
            "hadith_number": clean_text(row.get("hadith_number")),
            "narrator": clean_text(row.get("narrator")),
            "text_ar": text_ar,
            "text_tr": text_tr,
            "text_en": text_en,
            "source_ar": source_ar,
            "source_tr": source_tr,
            "source_en": source_en,
            "grade": clean_text(row.get("grade")),
            "source_note": source_tr,
            "topics": clean_topics,
            "status": "approved",
        }
        if not (record["collection"] and record["book"] and record["hadith_number"] and record["narrator"] and record["grade"]):
            continue
        records.append(record)
    return records


def build_ayah_records(
    ayah_tr_ar_records: list[dict[str, Any]],
    ayah_en_map: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    for row in ayah_tr_ar_records:
        row_id = clean_text(row.get("id"))
        if not row_id:
            continue
        ref = ayah_en_map.get(row_id)
        if not ref:
            continue

        text_ar = clean_text(row.get("text"))
        text_tr = clean_text(row.get("translation"))
        translation = ref.get("translation", {}) if isinstance(ref.get("translation"), dict) else {}
        text_en = clean_text(translation.get("en"))
        source_ar = clean_text(ref.get("source_ar"))
        source_tr = clean_text(ref.get("source_tr"))
        source_en = clean_text(ref.get("source_en"))

        if not (text_ar and text_tr and text_en and source_ar and source_tr and source_en):
            continue

        topics = row.get("topics", [])
        if not isinstance(topics, list):
            topics = []
        clean_topics = [clean_text(t) for t in topics if clean_text(t)]
        if not clean_topics:
            clean_topics = ["genel"]

        record = {
            "id": row_id,
            "type": "ayah",
            "surah_name": clean_text(row.get("surah_name")),
            "surah_number": int(row.get("surah_number")),
            "ayah_number": int(row.get("ayah_number")),
            "text_ar": text_ar,
            "text_tr": text_tr,
            "text_en": text_en,
            "source_ar": source_ar,
            "source_tr": source_tr,
            "source_en": source_en,
            "meal_source": "Diyanet (tr) + Asad (en) source based",
            "source_note": clean_text(row.get("source_note")) or "source_based",
            "topics": clean_topics,
            "status": "approved",
        }
        if not record["surah_name"]:
            continue
        records.append(record)
    return records


def build_payload(content_type: str, records: list[dict[str, Any]]) -> dict[str, Any]:
    return {
        "schema_version": "2.0.0",
        "content_version": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
        "type": content_type,
        "records": records,
    }


def shuffled_ids(ids: list[str], label: str) -> list[str]:
    seed_raw = f"{label}|{'|'.join(ids)}"
    seed = int(hashlib.sha256(seed_raw.encode("utf-8")).hexdigest()[:16], 16)
    rng = random.Random(seed)
    out = ids[:]
    rng.shuffle(out)
    return out


def count_arabic_text(records: list[dict[str, Any]], field: str) -> int:
    total = 0
    for rec in records:
        value = rec.get(field)
        if isinstance(value, str) and ARABIC_RE.search(value):
            total += 1
    return total


def copy_for_archive(paths: list[Path]) -> list[FileStat]:
    ARCHIVE_DIR.mkdir(parents=True, exist_ok=True)
    stats: list[FileStat] = []
    for path in paths:
        rel = path.relative_to(REPO_ROOT)
        safe_name = "__".join(rel.parts[-4:])
        target = ARCHIVE_DIR / safe_name
        target.write_bytes(path.read_bytes())
        stats.append(file_stat(target))
    return stats


def main() -> None:
    hadith_tr_raw = load_json(HADITH_TR_SOURCE)
    hadith_ar_en_raw = load_json(HADITH_AR_EN_SOURCE)
    ayah_tr_ar_raw = load_json(AYAH_TR_AR_SOURCE)
    ayah_en_raw = load_json(AYAH_EN_SOURCE)

    hadith_tr_rows = hadith_tr_raw.get("records", []) if isinstance(hadith_tr_raw, dict) else []
    ayah_tr_ar_rows = ayah_tr_ar_raw.get("records", []) if isinstance(ayah_tr_ar_raw, dict) else []
    ayah_en_rows = ayah_en_raw if isinstance(ayah_en_raw, list) else []
    hadith_ar_en_rows = hadith_ar_en_raw if isinstance(hadith_ar_en_raw, list) else []

    hadith_records = build_hadith_records(
        hadith_tr_records=[r for r in hadith_tr_rows if isinstance(r, dict)],
        hadith_ar_en_map=list_to_map_by_id([r for r in hadith_ar_en_rows if isinstance(r, dict)]),
    )
    ayah_records = build_ayah_records(
        ayah_tr_ar_records=[r for r in ayah_tr_ar_rows if isinstance(r, dict)],
        ayah_en_map=list_to_map_by_id([r for r in ayah_en_rows if isinstance(r, dict)]),
    )

    hadith_payload = build_payload("hadith", hadith_records)
    ayah_payload = build_payload("ayah", ayah_records)

    ayah_ids = [clean_text(r.get("id")) for r in ayah_records if clean_text(r.get("id"))]
    hadith_ids = [clean_text(r.get("id")) for r in hadith_records if clean_text(r.get("id"))]
    sequence_payload = {
        "schema_version": "1.0.0",
        "content_version": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
        "start_date": SEQUENCE_START_DATE,
        "ayah_order_ids": shuffled_ids(ayah_ids, "ayah"),
        "hadith_order_ids": shuffled_ids(hadith_ids, "hadith"),
    }

    # Archive cleanup request: overwrite hadith draft list with <=300 Turkish set.
    filtered_hadith_draft = []
    for row in hadith_ar_en_rows:
        if not isinstance(row, dict):
            continue
        tr_text = clean_text(row.get("text_tr"))
        if tr_text and len(tr_text) <= HADITH_TR_MAX_CHARS:
            filtered = dict(row)
            filtered["text_tr"] = tr_text
            filtered_hadith_draft.append(filtered)
    save_json(HADITH_AR_EN_SOURCE, filtered_hadith_draft)

    # Keep canonical tri-language hadith archive aligned with publish source file name.
    save_json(HADITH_TR_SOURCE, hadith_payload)

    save_json(HADITH_PUBLISH, hadith_payload)
    save_json(AYAH_PUBLISH, ayah_payload)
    save_json(SEQUENCE_PUBLISH, sequence_payload)
    save_json(HADITH_ASSET, hadith_payload)
    save_json(AYAH_ASSET, ayah_payload)
    save_json(SEQUENCE_ASSET, sequence_payload)

    archived = copy_for_archive(
        [
            HADITH_AR_EN_SOURCE,
            HADITH_TR_SOURCE,
            AYAH_TR_AR_SOURCE,
            AYAH_EN_SOURCE,
            HADITH_PUBLISH,
            AYAH_PUBLISH,
            SEQUENCE_PUBLISH,
            HADITH_ASSET,
            AYAH_ASSET,
            SEQUENCE_ASSET,
        ]
    )

    manifest = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "source_inputs": [
            str(HADITH_AR_EN_SOURCE.relative_to(REPO_ROOT)),
            str(HADITH_TR_SOURCE.relative_to(REPO_ROOT)),
            str(AYAH_TR_AR_SOURCE.relative_to(REPO_ROOT)),
            str(AYAH_EN_SOURCE.relative_to(REPO_ROOT)),
        ],
        "publish_outputs": [
            str(HADITH_PUBLISH.relative_to(REPO_ROOT)),
            str(AYAH_PUBLISH.relative_to(REPO_ROOT)),
            str(SEQUENCE_PUBLISH.relative_to(REPO_ROOT)),
            str(HADITH_ASSET.relative_to(REPO_ROOT)),
            str(AYAH_ASSET.relative_to(REPO_ROOT)),
            str(SEQUENCE_ASSET.relative_to(REPO_ROOT)),
        ],
        "stats": {
            "hadith_record_count": len(hadith_records),
            "ayah_record_count": len(ayah_records),
            "hadith_tr_max_chars": HADITH_TR_MAX_CHARS,
            "hadith_arabic_text_count": count_arabic_text(hadith_records, "text_ar"),
            "ayah_arabic_text_count": count_arabic_text(ayah_records, "text_ar"),
            "sequence_start_date": SEQUENCE_START_DATE,
        },
        "archive_files": [
            {
                "path": str(stat.path.relative_to(REPO_ROOT)),
                "sha256": stat.sha256,
                "size_bytes": stat.size,
            }
            for stat in archived
        ],
    }
    save_json(MANIFEST, manifest)

    print("publish payloads generated")
    print(f"hadith records: {len(hadith_records)}")
    print(f"ayah records: {len(ayah_records)}")
    print(f"sequence start: {SEQUENCE_START_DATE}")
    print(f"manifest: {MANIFEST}")


if __name__ == "__main__":
    main()
