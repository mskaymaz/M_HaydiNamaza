from __future__ import annotations

from .models import ApprovedRecord, AyahRecord, BaseRecord, EsmaRecord, HadithRecord, PRIORITY_VALUES, STATUS_VALUES


def validate_status(status: str) -> str:
    value = str(status or "").strip().lower()
    if value not in STATUS_VALUES:
        raise ValueError(f"Gecersiz status: {status}")
    return value


def validate_priority(priority: int) -> int:
    if int(priority) not in PRIORITY_VALUES:
        raise ValueError(f"Gecersiz priority: {priority}")
    return int(priority)


def validate_record(record: BaseRecord) -> None:
    if not record.id.strip():
        raise ValueError("Record id bos olamaz.")
    if not record.ref.strip():
        raise ValueError("Record ref bos olamaz.")
    if not str(record.ar).strip() and not str(record.tr).strip() and not str(record.en).strip():
        raise ValueError("En az bir dilde metin olmali.")
    validate_status(record.status)
    validate_priority(record.priority)
    if isinstance(record, AyahRecord):
        if not record.surah_number or not (1 <= int(record.surah_number) <= 114):
            raise ValueError("Ayet kaydinda gecerli sure numarasi olmali.")
        if not record.ayah_number or int(record.ayah_number) <= 0:
            raise ValueError("Ayet kaydinda gecerli ayet numarasi olmali.")
    if isinstance(record, HadithRecord):
        if not record.hadith_number or int(record.hadith_number) <= 0:
            raise ValueError("Hadis kaydinda gecerli hadis numarasi olmali.")
    if isinstance(record, EsmaRecord):
        if not record.esma_number or int(record.esma_number) <= 0:
            raise ValueError("Esma kaydinda gecerli esma numarasi olmali.")


def validate_approved_record(record: ApprovedRecord) -> None:
    if not record.id.strip():
        raise ValueError("Approved record id bos olamaz.")
    if not record.ref.strip():
        raise ValueError("Approved record ref bos olamaz.")
    if not str(record.ar).strip() and not str(record.tr).strip() and not str(record.en).strip():
        raise ValueError("Approved record en az bir dilde metin icermeli.")
    validate_priority(record.priority)
    if record.kind == "ayah":
        if not record.surah_number or not record.ayah_number:
            raise ValueError("Approved ayet kaydinda sure ve ayet numarasi olmali.")
    if record.kind == "hadith":
        if not record.hadith_number:
            raise ValueError("Approved hadis kaydinda hadis numarasi olmali.")
    if record.kind == "esma":
        if not record.esma_number:
            raise ValueError("Approved esma kaydinda esma numarasi olmali.")
