from __future__ import annotations

from copy import deepcopy
from typing import Any

from ..matchers.hadith_matcher import build_hadith_match_summary
from ..models import FetchResult, SourceInfo
from ..quality.hadith_quality_checker import build_hadith_quality
from .diyanet_hadith_tr_loader import extract_diyanet_tr
from .hadith_loader import load_hadith_seed_payload
from .sunnah_hadith_loader import extract_sunnah_ar_en


class HadithSeedProvider:
    def __init__(self) -> None:
        self._loaded = False
        self._payload: dict[str, Any] = {}
        self._path = None
        self._by_number: dict[int, dict[str, Any]] = {}

    def fetch(self, hadith_number: int) -> FetchResult:
        try:
            self._ensure_loaded()
        except Exception as exc:
            return FetchResult(
                success=False,
                status_label="local_hadith_source_missing",
                source_info=SourceInfo(label="Hadis yerel seed", fetch_status="local_hadith_source_missing"),
                error=str(exc),
            )

        exact = self._by_number.get(hadith_number)
        if exact is not None:
            raw_record = deepcopy(exact)
            return self._success_result(raw_record, "local_hadith_exact", hadith_number)

        nearby = self._find_nearby(hadith_number)
        if nearby is not None:
            raw_record = deepcopy(nearby)
            return self._success_result(raw_record, "local_hadith_nearby", hadith_number)

        return FetchResult(
            success=False,
            status_label="local_hadith_missing",
            source_info=SourceInfo(
                label="Hadis yerel seed",
                source_ref=f"riyazussalihin/{hadith_number}",
                fetch_status="local_hadith_missing",
            ),
            error="Istenen hadis yerel seed havuzunda bulunamadi.",
        )

    def _ensure_loaded(self) -> None:
        if self._loaded:
            return
        payload, path = load_hadith_seed_payload()
        self._payload = payload
        self._path = path
        for item in payload.get("items", []):
            if not isinstance(item, dict):
                continue
            number = item.get("hadithNo")
            try:
                parsed = int(number)
            except (TypeError, ValueError):
                continue
            self._by_number[parsed] = item
        self._loaded = True

    def _find_nearby(self, hadith_number: int) -> dict[str, Any] | None:
        for offset in (1, 2, 3):
            for candidate in (hadith_number - offset, hadith_number + offset):
                if candidate in self._by_number:
                    return self._by_number[candidate]
        return None

    def _success_result(self, raw_record: dict[str, Any], status_label: str, target_hadith_no: int) -> FetchResult:
        input_block = raw_record.get("input")
        if isinstance(input_block, dict):
            input_block["hadithNo_diyanet"] = target_hadith_no
        match_summary = build_hadith_match_summary(target_hadith_no, raw_record)
        raw_record["quality"] = build_hadith_quality(raw_record, match_summary)
        tr, tr_source = extract_diyanet_tr(raw_record)
        ar, en, ar_en_source = extract_sunnah_ar_en(raw_record)
        source_info = raw_record.get("sourceInfo") if isinstance(raw_record.get("sourceInfo"), dict) else {}
        source_info.setdefault("tr", tr_source)
        source_info.setdefault("ar_en", ar_en_source)
        raw_record["sourceInfo"] = source_info
        return FetchResult(
            success=True,
            status_label=status_label,
            source_info=SourceInfo(
                label="Diyanet TR + Sunnah yerel seed",
                source_ref=str(raw_record.get("ref") or ""),
                fetch_status=status_label,
                details={"seedPath": str(self._path or ""), "raw_record": raw_record},
            ),
            ar=ar,
            tr=tr,
            en=en,
            extra={"raw_record": raw_record},
        )
