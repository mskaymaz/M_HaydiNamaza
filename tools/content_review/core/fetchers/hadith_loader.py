from __future__ import annotations

import json
from pathlib import Path
from typing import Any


def default_hadith_seed_paths() -> list[Path]:
    repo_root = Path(__file__).resolve().parents[4]
    return [
        repo_root / "Besmele" / "data" / "content_seed" / "hadis" / "hadiths.pending_review.440.clean_sunnah_ar_en.v1.json",
        repo_root / "Besmele" / "data" / "content_seed" / "hadiths.pending_review.v1.json",
    ]


def load_hadith_seed_payload() -> tuple[dict[str, Any], Path]:
    for path in default_hadith_seed_paths():
        if not path.exists():
            continue
        with path.open("r", encoding="utf-8-sig") as handle:
            payload = json.load(handle)
        if isinstance(payload, dict) and isinstance(payload.get("items"), list):
            return payload, path
    raise FileNotFoundError("Yerel hadis seed dosyasi bulunamadi.")
