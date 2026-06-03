from __future__ import annotations

from copy import deepcopy
from typing import Any

from ..models import FetchResult, SourceInfo
from ..text_normalizer import normalize_storage_text
from .tanzil_loader import load_tanzil_full_index, load_tanzil_seed_payload


class TanzilAyahProvider:
    def __init__(self) -> None:
        self._loaded = False
        self._payload: dict[str, Any] = {}
        self._path = None
        self._full_paths: dict[str, Any] = {}
        self._top_level_by_ref: dict[str, dict[str, Any]] = {}
        self._ayah_by_ref: dict[str, dict[str, Any]] = {}
        self._full_index: dict[str, dict[str, str]] = {}

    def fetch(self, normalized: dict[str, object]) -> FetchResult:
        try:
            self._ensure_loaded()
        except Exception as exc:
            return FetchResult(
                success=False,
                status_label="local_source_missing",
                source_info=SourceInfo(label="Tanzil yerel kaynak", fetch_status="local_source_missing"),
                error=str(exc),
            )

        ref = str(normalized["ref"])
        if ref in self._top_level_by_ref:
            raw_record = deepcopy(self._top_level_by_ref[ref])
            self._prepare_raw_record(raw_record, normalized)
            return self._success_result(raw_record, "local_seed_exact")

        raw_record = self._build_from_full_index(normalized)
        if raw_record is None:
            return FetchResult(
                success=False,
                status_label="local_source_missing",
                source_info=SourceInfo(label="Tanzil yerel kaynak", source_ref=ref, fetch_status="local_source_missing"),
                error="Istenen ayet yerel Tanzil tam havuzunda bulunamadi.",
            )
        return self._success_result(raw_record, "local_seed_generated")

    def _ensure_loaded(self) -> None:
        if self._loaded:
            return
        payload, path = load_tanzil_seed_payload()
        self._payload = payload
        self._path = path
        self._full_index, self._full_paths = load_tanzil_full_index()
        for item in payload.get("items", []):
            if not isinstance(item, dict):
                continue
            item_ref = str(item.get("ref") or item.get("id") or "").strip()
            if item_ref:
                self._top_level_by_ref[item_ref] = item
            for ayah in item.get("ayahs", []):
                if not isinstance(ayah, dict):
                    continue
                ayah_ref = str(ayah.get("ref") or "").strip()
                if ayah_ref and ayah_ref not in self._ayah_by_ref:
                    self._ayah_by_ref[ayah_ref] = ayah
        self._loaded = True

    def _build_from_full_index(self, normalized: dict[str, object]) -> dict[str, Any] | None:
        surah_number = int(normalized["surah_number"])
        ayah_start = int(normalized["ayah_start"])
        ayah_end = int(normalized["ayah_end"])
        ayah_items: list[dict[str, Any]] = []
        for ayah_no in range(ayah_start, ayah_end + 1):
            ref = f"{surah_number:03d}/{ayah_no:03d}"
            item = self._build_single_ayah_item(ref, surah_number, ayah_no)
            if item is None:
                return None
            ayah_items.append(item)

        source_summary = self._payload.get("metadata", {}).get("sources", {})
        raw = {
            "ref": str(normalized["ref"]),
            "id": str(normalized["id"]),
            "surah": surah_number,
            "ayahStart": ayah_start,
            "ayahEnd": ayah_end,
            "type": str(normalized.get("record_type") or "single"),
            "ayahCount": int(normalized.get("ayah_count") or len(ayah_items)),
            "input": {
                "sira": None,
                "ref": str(normalized["ref"]),
                "input_type": "aralik" if ayah_start != ayah_end else "tekil",
                "input_ayah_count": int(normalized.get("ayah_count") or len(ayah_items)),
                "input_char_count": 0,
                "input_status": "tool_ekle",
                "input_source_ref_groups": str(normalized["ref"]),
            },
            "source": {
                "arabic": "Tanzil Uthmani Quran Text",
                "tr": "Tanzil tr.bulac / Ali Bulac",
                "trAlt": "Tanzil tr.diyanet / Diyanet Isleri",
                "en": "Tanzil en.sahih / Saheeh International",
                "enAlt": "Tanzil en.maududi / Abul A'la Maududi",
            },
            "sourceRefGroups": [str(normalized["ref"])],
            "ayahs": ayah_items,
            "status": "pending_review",
            "review": {
                "status": "pending_review",
                "priority_key": "normal",
                "priority": 3,
                "boost": {"enabled": False, "weight": 1},
                "note": "",
                "updated_at": None,
            },
            "sourceInfo": {
                "label": "Tanzil tam yerel kaynak",
                "source_ref": str(self._full_paths.get("ar") or self._path),
                "fetch_status": "local_seed_generated",
                "details": {"metadata_sources": source_summary, "quranFiles": {k: str(v) for k, v in self._full_paths.items()}},
            },
        }
        self._prepare_raw_record(raw, normalized)
        return raw

    def _build_single_ayah_item(self, ref: str, surah_number: int, ayah_no: int) -> dict[str, Any] | None:
        source = self._full_index.get(ref)
        if source:
            return {
                "ref": ref,
                "surah": surah_number,
                "ayah": ayah_no,
                "arabic": normalize_storage_text(str(source.get("arabic") or "")),
                "tr": {
                    "source": "Tanzil tr.bulac / Ali Bulac",
                    "sourceRef": ref,
                    "text": normalize_storage_text(str(source.get("tr_main") or "")),
                },
                "en": {
                    "source": "Tanzil en.sahih / Saheeh International",
                    "sourceRef": ref,
                    "text": normalize_storage_text(str(source.get("en_main") or "")),
                },
                "alternatives": {
                    "tr_diyanet_tanzil": {
                        "source": "Tanzil tr.diyanet / Diyanet Isleri",
                        "text": normalize_storage_text(str(source.get("tr_alt") or "")),
                    },
                    "en_maududi": {
                        "source": "Tanzil en.maududi / Abul A'la Maududi",
                        "text": normalize_storage_text(str(source.get("en_alt") or "")),
                    },
                },
            }
        seed_item = self._ayah_by_ref.get(ref)
        return deepcopy(seed_item) if isinstance(seed_item, dict) else None

    def _prepare_raw_record(self, raw_record: dict[str, Any], normalized: dict[str, object]) -> None:
        ayahs = raw_record.get("ayahs", [])
        ar_parts: list[str] = []
        tr_parts: list[str] = []
        en_parts: list[str] = []
        for ayah in ayahs:
            if not isinstance(ayah, dict):
                continue
            ar_parts.append(normalize_storage_text(str(ayah.get("arabic") or "")))
            tr_obj = ayah.get("tr")
            en_obj = ayah.get("en")
            if isinstance(tr_obj, dict):
                tr_parts.append(normalize_storage_text(str(tr_obj.get("text") or "")))
            if isinstance(en_obj, dict):
                en_parts.append(normalize_storage_text(str(en_obj.get("text") or "")))
        raw_record["id"] = str(normalized["id"])
        raw_record["ref"] = str(normalized["ref"])
        raw_record["surah"] = int(normalized["surah_number"])
        raw_record["surah_name"] = str(normalized["surah_name"])
        raw_record["ayahStart"] = int(normalized["ayah_start"])
        raw_record["ayahEnd"] = int(normalized["ayah_end"])
        raw_record["ayahCount"] = int(normalized["ayah_count"])
        raw_record["type"] = str(normalized["record_type"])
        raw_record["text_ar"] = "\n\n".join(part for part in ar_parts if part)
        raw_record["text_tr"] = "\n\n".join(part for part in tr_parts if part)
        raw_record["text_en"] = "\n\n".join(part for part in en_parts if part)
        raw_record["status"] = "pending_review"
        review = raw_record.get("review")
        if not isinstance(review, dict):
            review = {}
            raw_record["review"] = review
        review["status"] = "pending_review"
        review["priority"] = int(review.get("priority") or 3)
        review["note"] = str(review.get("note") or "")
        input_block = raw_record.get("input")
        if isinstance(input_block, dict):
            input_block["ref"] = str(normalized["ref"])
            input_block["input_type"] = "aralik" if int(normalized["ayah_count"]) > 1 else "tekil"
            input_block["input_ayah_count"] = int(normalized["ayah_count"])

    def _success_result(self, raw_record: dict[str, Any], status_label: str) -> FetchResult:
        return FetchResult(
            success=True,
            status_label=status_label,
            source_info=SourceInfo(
                label="Tanzil yerel kaynak",
                source_ref=str(raw_record.get("ref") or ""),
                fetch_status=status_label,
                details={"seedPath": str(self._path or ""), "source": raw_record.get("source"), "raw_record": raw_record},
            ),
            ar=str(raw_record.get("text_ar") or ""),
            tr=str(raw_record.get("text_tr") or ""),
            en=str(raw_record.get("text_en") or ""),
            extra={"raw_record": raw_record},
        )
