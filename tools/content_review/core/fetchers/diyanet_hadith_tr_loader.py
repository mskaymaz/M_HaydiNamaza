from __future__ import annotations

from typing import Any

from ..text_normalizer import normalize_storage_text


def extract_diyanet_tr(raw_record: dict[str, Any]) -> tuple[str, dict[str, Any]]:
    text = ""
    text_obj = raw_record.get("text")
    if isinstance(text_obj, dict):
        tr_obj = text_obj.get("tr")
        if isinstance(tr_obj, dict):
            text = str(tr_obj.get("clean") or tr_obj.get("sourceText") or "").strip()

    source_info = raw_record.get("sourceInfo") if isinstance(raw_record.get("sourceInfo"), dict) else {}
    display = source_info.get("display") if isinstance(source_info.get("display"), dict) else {}
    input_block = raw_record.get("input") if isinstance(raw_record.get("input"), dict) else {}
    details = {
        "sourceName": "Diyanet Dijital Riyazus-Salihin",
        "sourceType": "seed/json",
        "reference": str(display.get("tr") or input_block.get("source_tr") or "").strip(),
    }
    return normalize_storage_text(text), details
