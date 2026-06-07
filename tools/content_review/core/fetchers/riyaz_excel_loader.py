from __future__ import annotations

from pathlib import Path
from typing import Any
from xml.etree import ElementTree as ET
from zipfile import ZipFile


NS = {
    "m": "http://schemas.openxmlformats.org/spreadsheetml/2006/main",
    "r": "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
}


def load_riyaz_excel_payload(path: Path) -> dict[str, Any]:
    with ZipFile(path) as archive:
        shared_strings = _read_shared_strings(archive)
        sheet_path = _find_hadisler_sheet_path(archive)
        sheet = ET.fromstring(archive.read(sheet_path))
        rows = [_read_row(row, shared_strings) for row in sheet.findall(".//m:sheetData/m:row", NS)]

    if not rows:
        raise ValueError(f"Riyaz Excel bos okunuyor: {path}")

    headers = rows[0]
    items = [_row_to_item(headers, row) for row in rows[1:]]
    return {
        "type": "riyaz_excel_seed",
        "source": str(path),
        "items": [item for item in items if item is not None],
    }


def _read_shared_strings(archive: ZipFile) -> list[str]:
    if "xl/sharedStrings.xml" not in archive.namelist():
        return []
    root = ET.fromstring(archive.read("xl/sharedStrings.xml"))
    return ["".join(t.text or "" for t in item.findall(".//m:t", NS)) for item in root.findall("m:si", NS)]


def _find_hadisler_sheet_path(archive: ZipFile) -> str:
    workbook = ET.fromstring(archive.read("xl/workbook.xml"))
    rels = ET.fromstring(archive.read("xl/_rels/workbook.xml.rels"))
    rel_by_id = {rel.attrib["Id"]: rel.attrib["Target"] for rel in rels}

    fallback = ""
    for sheet in workbook.findall(".//m:sheet", NS):
        rel_id = sheet.attrib.get(f"{{{NS['r']}}}id", "")
        target = rel_by_id.get(rel_id, "")
        path = "xl/" + target.lstrip("/")
        if not fallback:
            fallback = path
        if sheet.attrib.get("name") == "Hadisler":
            return path
    if fallback:
        return fallback
    raise ValueError("Riyaz Excel icinde sheet bulunamadi.")


def _read_row(row: ET.Element, shared_strings: list[str]) -> list[str]:
    values: list[str] = []
    for cell in row.findall("m:c", NS):
        index = _column_index(cell.attrib.get("r", ""))
        while len(values) <= index:
            values.append("")
        value_node = cell.find("m:v", NS)
        value = value_node.text if value_node is not None else ""
        if cell.attrib.get("t") == "s" and value:
            value = shared_strings[int(value)]
        values[index] = value
    return values


def _column_index(reference: str) -> int:
    letters = "".join(ch for ch in reference if ch.isalpha())
    value = 0
    for letter in letters:
        value = value * 26 + ord(letter.upper()) - ord("A") + 1
    return max(0, value - 1)


def _row_to_item(headers: list[str], row: list[str]) -> dict[str, Any] | None:
    data = {header: _cell(row, index) for index, header in enumerate(headers) if header}
    hadith_no = _safe_int(data.get("epub_no"))
    if hadith_no is None:
        return None

    sunnah_no = _safe_int(data.get("sunnah_no"))
    sunnah_url = data.get("sunnah_url", "")
    tr_source = data.get("kaynak_tr", "")
    en_source = data.get("source_en", "")
    ar_source = data.get("arabic_source_raw", "")
    notes = _split_notes(data.get("notlar", ""), data.get("CPT_translation_note", ""), data.get("CPT_translation_status", ""))
    confidence = str(data.get("guven", "") or "").strip()
    match_status = str(data.get("eslesme_durumu", "") or "").strip()

    return {
        "id": f"hadith-riyaz-{hadith_no:04d}",
        "ref": f"riyazussalihin/{hadith_no}",
        "hadithNo": hadith_no,
        "status": "pending_review",
        "groupKey": "riyazussalihin",
        "input": {
            "hadithNo_diyanet": hadith_no,
            "source_tr": tr_source,
            "source_en": en_source,
            "source_ar": ar_source,
            "matchStatus": match_status,
        },
        "text": {
            "ar": {
                "clean": data.get("sunnah.com_arabic_full_text", "") or data.get("diyanet_arabic_full_text", ""),
                "sourceText": data.get("sunnah.com_arabic_full_text", "") or data.get("diyanet_arabic_full_text", ""),
            },
            "tr": {
                "clean": data.get("turkish_full_text", "") or data.get("CPT_turkish_translation", ""),
                "sourceText": data.get("turkish_full_text", "") or data.get("CPT_turkish_translation", ""),
            },
            "en": {
                "clean": data.get("english_full_text", "") or data.get("CPT_english_translation", ""),
                "sourceText": data.get("english_full_text", "") or data.get("CPT_english_translation", ""),
            },
        },
        "sourceInfo": {
            "label": "Riyaz 1900 Excel",
            "display": {
                "ar": ar_source,
                "tr": tr_source,
                "en": en_source,
            },
            "sunnah": {
                "candidateNo": sunnah_no or hadith_no,
                "candidateUrl": sunnah_url,
                "matchStatus": match_status,
            },
            "primaryCollection": {
                "title_tr": "Riyazus Salihin",
                "title_en": "Riyad as-Salihin",
            },
            "chapter": {
                "title_tr": data.get("diyanet_konu", ""),
                "title_en": data.get("sunnah_bolum", ""),
            },
        },
        "quality": {
            "matchConfidence": confidence,
            "matchStatus": match_status,
            "notes": notes,
        },
        "rawExcel": data,
    }


def _cell(row: list[str], index: int) -> str:
    return str(row[index]).strip() if index < len(row) else ""


def _safe_int(value: Any) -> int | None:
    try:
        if value is None or value == "":
            return None
        return int(float(str(value)))
    except (TypeError, ValueError):
        return None


def _split_notes(*values: str) -> list[str]:
    notes: list[str] = []
    for value in values:
        for part in str(value or "").replace("\r", "\n").split("\n"):
            text = part.strip()
            if text and text not in notes:
                notes.append(text)
    return notes
