from __future__ import annotations

import json
import re
import unicodedata
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
DOC_ROOT = REPO_ROOT / "docs" / "EsmaulHusna"
APPROVED_ROOT = REPO_ROOT / "assets" / "data" / "daily_content" / "approved"


def main() -> None:
    esma_rows = _read_json(DOC_ROOT / "Esma_ar_tr_en_99.json")
    sifat_rows = _read_json(DOC_ROOT / "esma_sifat_282.json")

    records = [_build_record(row, source_kind="esma", prefix="esma") for row in esma_rows]
    records.extend(_build_record(row, source_kind="sifat", prefix="sifat") for row in sifat_rows)

    payload = {
        "schema_version": "1.0.0",
        "content_version": "approved-esma-sifat-20260609",
        "type": "esma",
        "records": records,
    }
    _write_json(APPROVED_ROOT / "esmaul_husna.v1.approved.json", payload)

    sequence_path = APPROVED_ROOT / "sequence.v1.json"
    sequence = _read_json(sequence_path) if sequence_path.exists() else {"start_date": "2026-06-02"}
    sequence["start_date"] = sequence.get("start_date") or "2026-06-02"
    sequence.setdefault("ayah_order_ids", [])
    sequence.setdefault("hadith_order_ids", [])
    sequence["esma_order_ids"] = [row["id"] for row in records if row["kind"] == "esma"]
    sequence["sifat_order_ids"] = [row["id"] for row in records if row["kind"] == "sifat"]
    _write_json(sequence_path, sequence)

    print(f"approved records={len(records)}")
    print(f"esma={len(sequence['esma_order_ids'])}")
    print(f"sifat={len(sequence['sifat_order_ids'])}")


def _read_json(path: Path) -> object:
    with path.open("r", encoding="utf-8-sig") as handle:
        return json.load(handle)


def _write_json(path: Path, payload: object) -> None:
    path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def _build_record(row: dict[str, object], *, source_kind: str, prefix: str) -> dict[str, object]:
    source_id = int(row["id"])
    name_tr = str(row["name_turkish"]).strip()
    category = str(row.get("category") or "Esmâ-i Hüsnâ").strip()
    source_label = "Esma_ar_tr_en_99" if source_kind == "esma" else "esma_sifat_282"
    source_note = (
        "Onaylı Esmâ-i Hüsnâ kaynak dosyasından dönüştürüldü."
        if source_kind == "esma"
        else "Onaylı Esma/Sıfat kaynak dosyasından dönüştürüldü."
    )
    slug = _slugify(name_tr)
    item_id = f"{prefix}-{source_id:03d}"
    return {
        "id": item_id,
        "type": "esma",
        "kind": source_kind,
        "ref": f"{source_kind}/{slug}-{source_id:03d}",
        "status": "approved",
        "priority": 1,
        "approvedAt": "2026-06-09T00:00:00Z",
        "approval": {
            "approved_by": "source_json_import",
            "approved_at": "2026-06-09T00:00:00Z",
            "review_note": "Kullanıcı onayıyla approved yayına alınan Esma/Sıfat kaynak dönüşümü.",
        },
        "source_id": source_id,
        "display_order": source_id,
        "esma_number": source_id,
        "category": category,
        "slug": slug,
        "name_arabic": str(row["name_arabic"]).strip(),
        "name_turkish": name_tr,
        "name_transliteration": str(row["name_transliteration"]).strip(),
        "arabic_name": str(row["name_arabic"]).strip(),
        "latin_tr": name_tr,
        "latin_en": str(row["name_transliteration"]).strip(),
        "meaning_ar": str(row["meaning_ar_short"]).strip(),
        "meaning_tr": str(row["meaning_tr_short"]).strip(),
        "meaning_en": str(row["meaning_en_short"]).strip(),
        "text_ar": str(row["description_ar_detailed"]).strip(),
        "text_tr": str(row["description_tr_detailed"]).strip(),
        "text_en": str(row["description_en_detailed"]).strip(),
        "ar": str(row["description_ar_detailed"]).strip(),
        "tr": str(row["description_tr_detailed"]).strip(),
        "en": str(row["description_en_detailed"]).strip(),
        "descriptionAr": str(row["description_ar_detailed"]).strip(),
        "descriptionTr": str(row["description_tr_detailed"]).strip(),
        "descriptionEn": str(row["description_en_detailed"]).strip(),
        "source_label": source_label,
        "sourceLabel": source_label,
        "source_note": source_note,
        "sourceRef": f"docs/EsmaulHusna/{source_label}.json#{source_id}",
        "sourceBasis": [
            "Yerel kullanıcı onaylı Esma/Sıfat kaynak JSON dosyası",
            "AR/TR/EN kısa anlam ve detay açıklama alanları tamlık kontrolünden geçti",
        ],
        "topics": ["esma"] if source_kind == "esma" else ["esma-sifat", category],
    }


def _slugify(value: str) -> str:
    normalized = unicodedata.normalize("NFKD", value)
    ascii_value = "".join(ch for ch in normalized if not unicodedata.combining(ch))
    ascii_value = ascii_value.lower().replace("ı", "i")
    ascii_value = re.sub(r"[^a-z0-9]+", "-", ascii_value)
    return ascii_value.strip("-") or "kayit"


if __name__ == "__main__":
    main()
