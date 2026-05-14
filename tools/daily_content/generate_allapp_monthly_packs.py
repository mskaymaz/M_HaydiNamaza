#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[2]
PRIVATE_PUBLISH_DIR = REPO_ROOT / "Besmele" / "data" / "daily_panel" / "publish"
HADITH_SOURCE = PRIVATE_PUBLISH_DIR / "hadiths.v1.approved.json"
AYAH_SOURCE = PRIVATE_PUBLISH_DIR / "ayahs.v1.approved.json"
SEQUENCE_SOURCE = PRIVATE_PUBLISH_DIR / "sequence.v1.json"

ALLAPP_ROOT = REPO_ROOT / "AllApp" / "data" / "daily_content" / "v1"
PUBLISH_DIR = ALLAPP_ROOT / "publish"
SEQUENCE_DIR = ALLAPP_ROOT / "sequence"
MANIFEST_PATH = ALLAPP_ROOT / "manifest.json"


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)
    if not isinstance(data, dict):
        raise ValueError(f"Invalid root object: {path}")
    return data


def save_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")


def file_sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    hadith_payload = load_json(HADITH_SOURCE)
    ayah_payload = load_json(AYAH_SOURCE)
    sequence_payload = load_json(SEQUENCE_SOURCE)

    hadith_target = PUBLISH_DIR / "hadiths.v1.approved.json"
    ayah_target = PUBLISH_DIR / "ayahs.v1.approved.json"
    sequence_ayah_target = SEQUENCE_DIR / "ayah_ids.shuffled.v1.json"
    sequence_hadith_target = SEQUENCE_DIR / "hadith_ids.shuffled.v1.json"

    save_json(hadith_target, hadith_payload)
    save_json(ayah_target, ayah_payload)
    save_json(
        sequence_ayah_target,
        {
            "schema_version": "1.0.0",
            "content_version": sequence_payload.get("content_version", datetime.now(timezone.utc).strftime("%Y-%m-%d")),
            "ids": sequence_payload.get("ayah_order_ids", []),
        },
    )
    save_json(
        sequence_hadith_target,
        {
            "schema_version": "1.0.0",
            "content_version": sequence_payload.get("content_version", datetime.now(timezone.utc).strftime("%Y-%m-%d")),
            "ids": sequence_payload.get("hadith_order_ids", []),
        },
    )

    manifest = {
        "schema_version": "2.0.0",
        "content_version": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "root": "data/daily_content/v1",
        "publish_files": {
            "ayahs": {
                "path": "publish/ayahs.v1.approved.json",
                "sha256": file_sha256(ayah_target),
            },
            "hadiths": {
                "path": "publish/hadiths.v1.approved.json",
                "sha256": file_sha256(hadith_target),
            },
        },
        "sequence_files": {
            "ayah_ids": {
                "path": "sequence/ayah_ids.shuffled.v1.json",
                "sha256": file_sha256(sequence_ayah_target),
            },
            "hadith_ids": {
                "path": "sequence/hadith_ids.shuffled.v1.json",
                "sha256": file_sha256(sequence_hadith_target),
            },
        },
        "schedule": {
            "mode": "serial_by_day_deterministic",
            "start_date": sequence_payload.get("start_date", "2026-05-15"),
        },
        "selection_contract": {
            "segmentation": "single_list_no_monthly_chunks",
            "daily_pick": "order[(today-start_date) % len(order)]",
        },
    }
    save_json(MANIFEST_PATH, manifest)

    print("allapp sequence payloads generated")
    print(f"output: {ALLAPP_ROOT}")


if __name__ == "__main__":
    main()
