from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from .riyaz_excel_loader import load_riyaz_excel_payload


def default_hadith_seed_paths() -> list[Path]:
    repo_root = Path(__file__).resolve().parents[4]
    return [
        repo_root / "docs" / "1900_hadis_approve.xlsx",
        repo_root / "assets" / "data" / "daily_content" / "archive" / "hadiths.pending_review.440.clean_sunnah_ar_en.v1.json",
        repo_root / "assets" / "data" / "daily_content" / "archive" / "hadiths.pending_review.v1.json",
    ]


def load_hadith_seed_payload() -> tuple[dict[str, Any], Path]:
    for path in default_hadith_seed_paths():
        if not path.exists():
            continue
        if path.suffix.lower() == ".xlsx":
            payload = load_riyaz_excel_payload(path)
            if isinstance(payload.get("items"), list):
                return payload, path
            continue
        with path.open("r", encoding="utf-8-sig") as handle:
            payload = json.load(handle)
        if isinstance(payload, dict) and isinstance(payload.get("items"), list):
            return payload, path
    raise FileNotFoundError("Yerel hadis seed dosyasi bulunamadi.")
