from __future__ import annotations

from difflib import SequenceMatcher

from .models import BaseRecord, DuplicateCheckResult, DuplicateMatch


def _norm_text(value: str) -> str:
    return " ".join(str(value or "").lower().split())


def _similarity(left: str, right: str) -> float:
    left_norm = _norm_text(left)
    right_norm = _norm_text(right)
    if not left_norm or not right_norm:
        return 0.0
    shorter = min(len(left_norm), len(right_norm))
    longer = max(len(left_norm), len(right_norm))
    if longer and (2 * shorter / (shorter + longer)) < 0.93:
        return 0.0
    return SequenceMatcher(None, left_norm, right_norm).ratio()


def check_duplicates(
    candidate: BaseRecord,
    archive_records: list[BaseRecord],
    approved_records: list[BaseRecord],
) -> DuplicateCheckResult:
    result = DuplicateCheckResult()
    candidate_ar = _norm_text(candidate.ar)
    candidate_tr = candidate.tr
    candidate_en = candidate.en
    source_ref = str(candidate.source_info.source_ref or "").strip()

    for record in archive_records:
        if record.kind != candidate.kind:
            continue
        reasons: list[tuple[str, float]] = []
        if record.id != candidate.id and record.ref == candidate.ref:
            reasons.append(("ref", 1.0))
        if source_ref and source_ref == str(record.source_info.source_ref or "").strip():
            reasons.append(("sourceRef", 1.0))
        if candidate_ar and candidate_ar == _norm_text(record.ar):
            reasons.append(("arabic", 1.0))
        tr_score = _similarity(candidate_tr, record.tr)
        en_score = _similarity(candidate_en, record.en)
        if tr_score >= 0.93 or en_score >= 0.93:
            reasons.append(("similar_text", max(tr_score, en_score)))
        for reason, score in reasons:
            result.archive_matches.append(
                DuplicateMatch(record_id=record.id, reason=reason, score=score, ref=record.ref)
            )

    for record in approved_records:
        if record.kind != candidate.kind:
            continue
        reasons: list[tuple[str, float]] = []
        if record.id != candidate.id and record.ref == candidate.ref:
            reasons.append(("ref", 1.0))
        if candidate_ar and candidate_ar == _norm_text(record.ar):
            reasons.append(("arabic", 1.0))
        tr_score = _similarity(candidate_tr, record.tr)
        en_score = _similarity(candidate_en, record.en)
        if tr_score >= 0.93 or en_score >= 0.93:
            reasons.append(("similar_text", max(tr_score, en_score)))
        for reason, score in reasons:
            result.approved_matches.append(
                DuplicateMatch(record_id=record.id, reason=reason, score=score, ref=record.ref)
            )

    result.exists_in_archive = any(match.reason == "ref" for match in result.archive_matches)
    result.exists_in_approved = any(match.reason == "ref" for match in result.approved_matches)
    result.exact_duplicate = any(
        match.reason in {"ref", "sourceRef", "arabic"} and match.score >= 0.999
        for match in [*result.archive_matches, *result.approved_matches]
    )
    result.possible_duplicate = any(
        match.reason == "similar_text" and match.score >= 0.93
        for match in [*result.archive_matches, *result.approved_matches]
    )
    return result
