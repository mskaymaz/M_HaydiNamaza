#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
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
HADITH_INPUT = BASE_ARCHIVE / "hadiths_draft_DiyanetUnified_v2.json"
AYAH_INPUT = BASE_ARCHIVE / "ayahs_draft_Edit.json"

HADITH_PUBLISH = PUBLISH_DIR / "hadiths.v1.approved.json"
AYAH_PUBLISH = PUBLISH_DIR / "ayahs.v1.approved.json"
HADITH_ASSET = ASSET_DIR / "hadiths.v1.approved.json"
AYAH_ASSET = ASSET_DIR / "ayahs.v1.approved.json"
MANIFEST = ARCHIVE_DIR / "publish_manifest.json"

MOJIBAKE_MARKERS = ("Ã", "Ä", "Å", "â€™", "â€œ", "â€", "â€“", "â€”")
ARABIC_RE = re.compile(r"[\u0600-\u06FF]")

HADITH_ALLOWED_KEYS = [
    "id",
    "type",
    "collection",
    "book",
    "hadith_number",
    "narrator",
    "text",
    "translation",
    "grade",
    "source_note",
    "topics",
]
AYAH_ALLOWED_KEYS = [
    "id",
    "type",
    "surah_name",
    "surah_number",
    "ayah_number",
    "text",
    "translation",
    "meal_source",
    "source_note",
    "topics",
]


@dataclass
class FileStat:
    path: Path
    sha256: str
    size: int


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8-sig") as f:
        data = json.load(f)
    if not isinstance(data, dict):
        raise ValueError(f"JSON root object bekleniyordu: {path}")
    return data


def save_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")


def file_stat(path: Path) -> FileStat:
    raw = path.read_bytes()
    return FileStat(
        path=path,
        sha256=hashlib.sha256(raw).hexdigest(),
        size=len(raw),
    )


def mojibake_score(text: str) -> int:
    return sum(text.count(marker) for marker in MOJIBAKE_MARKERS)


def cp1252_fixes(text: str) -> str:
    replacements = {
        "â€™": "’",
        "â€œ": "“",
        "â€": "”",
        "â€“": "–",
        "â€”": "—",
        "â€¦": "…",
    }
    out = text
    for old, new in replacements.items():
        out = out.replace(old, new)
    return out


def maybe_fix_mojibake(text: str) -> str:
    if not text:
        return text
    best = cp1252_fixes(text)
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


def clean_value(value: Any) -> Any:
    if isinstance(value, str):
        return maybe_fix_mojibake(value).strip()
    if isinstance(value, list):
        return [clean_value(v) for v in value]
    if isinstance(value, dict):
        return {k: clean_value(v) for k, v in value.items()}
    return value


def keep_keys(record: dict[str, Any], allowed: list[str]) -> dict[str, Any]:
    out: dict[str, Any] = {}
    for key in allowed:
        out[key] = clean_value(record.get(key))
    return out


def count_markers_in_records(records: list[dict[str, Any]], fields: list[str]) -> int:
    total = 0
    for rec in records:
        for field in fields:
            value = rec.get(field)
            if isinstance(value, str):
                total += mojibake_score(value)
    return total


def count_arabic_text(records: list[dict[str, Any]], field: str) -> int:
    c = 0
    for rec in records:
        value = rec.get(field)
        if isinstance(value, str) and ARABIC_RE.search(value):
            c += 1
    return c


def build_publish_payload(source: dict[str, Any], expected_type: str, allowed: list[str]) -> dict[str, Any]:
    records = source.get("records")
    if not isinstance(records, list):
        raise ValueError(f"`records` list degil: {expected_type}")
    publish_records: list[dict[str, Any]] = []
    for record in records:
        if not isinstance(record, dict):
            continue
        if record.get("type") != expected_type:
            continue
        publish_records.append(keep_keys(record, allowed))
    return {
        "schema_version": source.get("schema_version", "1.0.0"),
        "content_version": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
        "type": expected_type,
        "records": publish_records,
    }


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
    hadith_src = load_json(HADITH_INPUT)
    ayah_src = load_json(AYAH_INPUT)

    hadith_src_records = [r for r in hadith_src.get("records", []) if isinstance(r, dict)]
    ayah_src_records = [r for r in ayah_src.get("records", []) if isinstance(r, dict)]

    hadith_before_markers = count_markers_in_records(hadith_src_records, ["text", "translation", "narrator", "source_note"])
    ayah_before_markers = count_markers_in_records(ayah_src_records, ["text", "translation", "surah_name", "source_note"])

    hadith_publish = build_publish_payload(hadith_src, "hadith", HADITH_ALLOWED_KEYS)
    ayah_publish = build_publish_payload(ayah_src, "ayah", AYAH_ALLOWED_KEYS)

    hadith_after_markers = count_markers_in_records(hadith_publish["records"], ["text", "translation", "narrator", "source_note"])
    ayah_after_markers = count_markers_in_records(ayah_publish["records"], ["text", "translation", "surah_name", "source_note"])

    save_json(HADITH_PUBLISH, hadith_publish)
    save_json(AYAH_PUBLISH, ayah_publish)
    save_json(HADITH_ASSET, hadith_publish)
    save_json(AYAH_ASSET, ayah_publish)

    archived = copy_for_archive(
        [
            HADITH_INPUT,
            AYAH_INPUT,
            HADITH_PUBLISH,
            AYAH_PUBLISH,
            HADITH_ASSET,
            AYAH_ASSET,
        ]
    )

    manifest = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "source_inputs": [str(HADITH_INPUT.relative_to(REPO_ROOT)), str(AYAH_INPUT.relative_to(REPO_ROOT))],
        "publish_outputs": [
            str(HADITH_PUBLISH.relative_to(REPO_ROOT)),
            str(AYAH_PUBLISH.relative_to(REPO_ROOT)),
            str(HADITH_ASSET.relative_to(REPO_ROOT)),
            str(AYAH_ASSET.relative_to(REPO_ROOT)),
        ],
        "removed_record_fields": ["status", "approval", "approval.approved_by", "approval.approved_at", "approval.review_note"],
        "stats": {
            "hadith_record_count": len(hadith_publish["records"]),
            "ayah_record_count": len(ayah_publish["records"]),
            "hadith_mojibake_markers_before": hadith_before_markers,
            "hadith_mojibake_markers_after": hadith_after_markers,
            "ayah_mojibake_markers_before": ayah_before_markers,
            "ayah_mojibake_markers_after": ayah_after_markers,
            "ayah_arabic_text_count": count_arabic_text(ayah_publish["records"], "text"),
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
    print(f"hadith records: {len(hadith_publish['records'])}")
    print(f"ayah records: {len(ayah_publish['records'])}")
    print(f"manifest: {MANIFEST}")


if __name__ == "__main__":
    main()
