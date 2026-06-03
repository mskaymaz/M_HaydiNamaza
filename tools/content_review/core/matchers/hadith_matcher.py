from __future__ import annotations

from typing import Any


def build_hadith_match_summary(target_hadith_no: int, raw_record: dict[str, Any]) -> dict[str, Any]:
    input_block = raw_record.get("input") if isinstance(raw_record.get("input"), dict) else {}
    source_info = raw_record.get("sourceInfo") if isinstance(raw_record.get("sourceInfo"), dict) else {}
    sunnah = source_info.get("sunnah") if isinstance(source_info.get("sunnah"), dict) else {}

    candidate_no = _safe_int(sunnah.get("candidateNo"))
    input_target_no = _safe_int(input_block.get("hadithNo_diyanet")) or target_hadith_no
    diff = None if candidate_no is None else candidate_no - input_target_no
    number_match = diff == 0 if diff is not None else False
    nearby_match = diff is not None and abs(diff) <= 3 and diff != 0
    method = str(sunnah.get("matchMethod") or input_block.get("matchMethod") or "").strip()
    status = str(sunnah.get("matchStatus") or input_block.get("matchStatus") or "").strip()
    score = _safe_int(sunnah.get("matchScore") or input_block.get("matchScore"))

    return {
        "targetHadithNo": input_target_no,
        "candidateNo": candidate_no,
        "difference": diff,
        "numberMatch": number_match,
        "nearbyMatch": nearby_match,
        "matchMethod": method,
        "matchStatus": status,
        "matchScore": score,
    }


def _safe_int(value: Any) -> int | None:
    try:
        if value is None or value == "":
            return None
        return int(value)
    except (TypeError, ValueError):
        return None
