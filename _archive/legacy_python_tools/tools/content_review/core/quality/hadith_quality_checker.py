from __future__ import annotations

from typing import Any


def build_hadith_quality(raw_record: dict[str, Any], match_summary: dict[str, Any]) -> dict[str, Any]:
    quality = dict(raw_record.get("quality") or {})
    status = str(match_summary.get("matchStatus") or "").lower()
    score = match_summary.get("matchScore")
    diff = match_summary.get("difference")
    number_match = bool(match_summary.get("numberMatch"))
    nearby_match = bool(match_summary.get("nearbyMatch"))

    confidence = quality.get("matchConfidence")
    if not confidence:
        if number_match and _is_high_status(status, score):
            confidence = "high"
        elif nearby_match or _is_medium_status(status, score):
            confidence = "medium"
        else:
            confidence = "low"

    match_status = quality.get("matchStatus")
    if not match_status:
        if confidence == "high":
            match_status = "verified_candidate"
        elif confidence == "medium":
            match_status = "needs_light_review"
        else:
            match_status = "manual_review_required"

    quality["matchConfidence"] = confidence
    quality["matchStatus"] = match_status
    quality["numberMatch"] = number_match
    quality["semanticMatch"] = quality.get("semanticMatch") or ("high" if confidence == "high" else "medium" if confidence == "medium" else "low")
    quality["narratorMatch"] = quality.get("narratorMatch") or "unknown"
    quality["topicMatch"] = quality.get("topicMatch") or "unknown"
    quality["needsManualReview"] = confidence == "low" or "manual" in match_status
    notes = list(quality.get("notes") or [])
    if diff not in (None, 0):
        notes.append(f"Hadis no farki: {diff:+d}")
    if score is not None:
        notes.append(f"Eslesme skoru: {score}")
    quality["notes"] = _dedupe_keep_order(notes)
    return quality


def _is_high_status(status: str, score: Any) -> bool:
    return "high" in status or (isinstance(score, int) and score >= 7000)


def _is_medium_status(status: str, score: Any) -> bool:
    return "medium" in status or "light" in status or (isinstance(score, int) and score >= 4000)


def _dedupe_keep_order(values: list[str]) -> list[str]:
    seen: set[str] = set()
    result: list[str] = []
    for value in values:
        text = str(value).strip()
        if not text or text in seen:
            continue
        seen.add(text)
        result.append(text)
    return result
