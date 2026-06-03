from __future__ import annotations

from typing import Any

from ..text_normalizer import normalize_storage_text


def extract_sunnah_ar_en(raw_record: dict[str, Any]) -> tuple[str, str, dict[str, Any]]:
    text_obj = raw_record.get("text") if isinstance(raw_record.get("text"), dict) else {}
    ar_obj = text_obj.get("ar") if isinstance(text_obj, dict) else {}
    en_obj = text_obj.get("en") if isinstance(text_obj, dict) else {}
    ar = normalize_storage_text(str(ar_obj.get("clean") or ar_obj.get("sourceText") or "").strip()) if isinstance(ar_obj, dict) else ""
    en = normalize_storage_text(str(en_obj.get("clean") or en_obj.get("sourceText") or "").strip()) if isinstance(en_obj, dict) else ""

    source_info = raw_record.get("sourceInfo") if isinstance(raw_record.get("sourceInfo"), dict) else {}
    sunnah = source_info.get("sunnah") if isinstance(source_info.get("sunnah"), dict) else {}
    details = {
        "sourceName": "Sunnah.com Riyad as-Salihin",
        "sourceType": "seed/json",
        "url": str(sunnah.get("candidateUrl") or source_info.get("source_ref") or "").strip(),
        "reference": f"Riyad as-Salihin {sunnah.get('candidateNo') or raw_record.get('hadithNo') or ''}".strip(),
        "matchStatus": str(sunnah.get("matchStatus") or "").strip(),
        "matchScore": sunnah.get("matchScore"),
    }
    return ar, en, details
