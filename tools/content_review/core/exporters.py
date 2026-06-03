from __future__ import annotations

from dataclasses import asdict
from copy import deepcopy

from .models import ApprovedRecord, AyahRecord, BaseRecord, HadithRecord


def to_approved_record(record: BaseRecord) -> ApprovedRecord:
    approved = ApprovedRecord(
        id=record.id,
        kind=record.kind,
        ref=record.ref,
        ar=record.ar,
        tr=record.tr,
        en=record.en,
        priority=record.priority,
        approved_at=record.approved_at,
    )
    if isinstance(record, AyahRecord):
        approved.surah_number = record.surah_number
        approved.surah_name = record.surah_name
        approved.ayah_number = record.ayah_number
    if isinstance(record, HadithRecord):
        approved.hadith_number = record.hadith_number
        approved.book_reference_tr = record.book_reference_tr
        approved.book_reference_en = record.book_reference_en
    return approved


def apply_record_to_raw(record: BaseRecord) -> dict:
    raw = dict(record.raw or {})
    raw["id"] = record.id
    raw["ref"] = record.ref
    raw["text_ar"] = record.ar
    raw["text_tr"] = record.tr
    raw["text_en"] = record.en
    raw["status"] = record.status
    raw["priority"] = record.priority
    raw["notes"] = record.notes
    raw["createdAt"] = record.created_at
    raw["updatedAt"] = record.updated_at
    raw["approvedAt"] = record.approved_at
    raw["sourceInfo"] = _merge_source_info(raw.get("sourceInfo"), record)
    raw["duplicateInfo"] = {
        "existsInArchive": record.duplicate_info.exists_in_archive,
        "existsInApproved": record.duplicate_info.exists_in_approved,
        "exactDuplicate": record.duplicate_info.exact_duplicate,
        "possibleDuplicate": record.duplicate_info.possible_duplicate,
        "archiveMatches": [asdict(item) for item in record.duplicate_info.archive_matches],
        "approvedMatches": [asdict(item) for item in record.duplicate_info.approved_matches],
    }
    raw["reviewHistory"] = list(record.review_history)
    review = dict(raw.get("review") or {})
    review["status"] = record.status
    review["priority"] = record.priority
    review["note"] = record.notes
    review["updated_at"] = record.updated_at
    raw["review"] = review

    if isinstance(record, AyahRecord):
        raw["surah"] = record.surah_number
        raw["surah_name"] = record.surah_name
        raw["ayah_number"] = record.ayah_number
    if isinstance(record, HadithRecord):
        raw["text"] = _merge_hadith_text(raw.get("text"), record)
        raw["hadithNo"] = record.hadith_number
        raw["hadith_number"] = record.hadith_number
        raw["book_reference_tr"] = record.book_reference_tr
        raw["book_reference_en"] = record.book_reference_en
        raw["quality"] = _merge_hadith_quality(raw.get("quality"))
    return raw


def _merge_source_info(existing: object, record: BaseRecord) -> dict:
    source_info = deepcopy(existing) if isinstance(existing, dict) else {}
    if not isinstance(source_info, dict):
        source_info = {}
    source_info["label"] = record.source_info.label
    source_info["source_ref"] = record.source_info.source_ref
    source_info["fetch_status"] = record.source_info.fetch_status
    details = record.source_info.details if isinstance(record.source_info.details, dict) else {}
    for key, value in details.items():
        if key == "raw_record":
            continue
        source_info.setdefault(key, value)
    return source_info


def _merge_hadith_text(existing: object, record: HadithRecord) -> dict:
    text = deepcopy(existing) if isinstance(existing, dict) else {}
    if not isinstance(text, dict):
        text = {}
    for language, value in (("ar", record.ar), ("tr", record.tr), ("en", record.en)):
        lang_obj = text.get(language)
        if not isinstance(lang_obj, dict):
            lang_obj = {}
        lang_obj["clean"] = value
        lang_obj["sourceText"] = value
        text[language] = lang_obj
    return text


def _merge_hadith_quality(existing: object) -> dict:
    quality = deepcopy(existing) if isinstance(existing, dict) else {}
    if not isinstance(quality, dict):
        quality = {}
    quality.setdefault("textCleaned", True)
    quality.setdefault("sourceSeparated", True)
    return quality
