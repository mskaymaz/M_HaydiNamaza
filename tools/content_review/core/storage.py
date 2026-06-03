from __future__ import annotations

import hashlib
import json
from dataclasses import asdict, replace
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from .backup import BackupManager
from .duplicate_checker import check_duplicates
from .exporters import apply_record_to_raw, to_approved_record
from .logger import ActionLogger
from .models import (
    AppPaths,
    ApprovedRecord,
    ArchiveLocation,
    AyahRecord,
    BaseRecord,
    ContentKind,
    DuplicateCheckResult,
    DuplicateMatch,
    HadithRecord,
    SourceInfo,
    ToolState,
)
from .reference_parser import SURAH_NAMES_TR
from .text_extractors import extract_trailing_reference
from .text_normalizer import normalize_record_texts
from .validators import validate_approved_record, validate_record


class StorageConflictError(RuntimeError):
    pass


class ContentRepository:
    def __init__(self, paths: AppPaths, logger: ActionLogger, backup_manager: BackupManager) -> None:
        self.paths = paths
        self.logger = logger
        self.backup_manager = backup_manager
        self._archive_payloads: dict[str, dict[str, Any]] = {}
        self._approved_payloads: dict[str, dict[str, Any]] = {}
        self._hashes: dict[Path, str] = {}
        self.state = self._load_state()
        self.reload()

    def reload(self) -> None:
        self._archive_payloads = {
            "ayah": self._read_payload(self.paths.archive_ayah_path),
            "hadith": self._read_payload(self.paths.archive_hadith_path),
        }
        self._approved_payloads = {
            "ayah": self._read_payload(self.paths.approved_ayah_path, default_type="approved"),
            "hadith": self._read_payload(self.paths.approved_hadith_path, default_type="approved"),
        }

    def list_archive_records(self, kind: ContentKind) -> list[BaseRecord]:
        payload = self._archive_payloads[kind]
        records = payload["records"]
        return [self._parse_archive_record(kind, raw, payload["path"], payload["root_key"], index) for index, raw in enumerate(records)]

    def list_approved_records(self, kind: ContentKind) -> list[BaseRecord]:
        payload = self._approved_payloads[kind]
        rows = payload["records"]
        return [self._parse_approved_record(kind, raw) for raw in rows]

    def find_archive_record(self, kind: ContentKind, ref: str) -> BaseRecord | None:
        for record in self.list_archive_records(kind):
            if record.ref == ref or record.id == ref:
                return record
        return None

    def find_approved_record(self, kind: ContentKind, ref: str) -> BaseRecord | None:
        for record in self.list_approved_records(kind):
            if record.ref == ref or record.id == ref:
                return record
        return None

    def build_duplicate_info(self, candidate: BaseRecord) -> DuplicateCheckResult:
        archive_records = [record for record in self.list_archive_records(candidate.kind) if record.id != candidate.id]
        approved_records = self.list_approved_records(candidate.kind)
        return check_duplicates(candidate, archive_records, approved_records)

    def save_record(self, record: BaseRecord) -> BaseRecord:
        ar, tr, en = normalize_record_texts(record.ar, record.tr, record.en)
        record = replace(record, ar=ar, tr=tr, en=en)
        validate_record(record)
        if isinstance(record, HadithRecord):
            clean_tr, ref_tr = extract_trailing_reference(record.tr, record.book_reference_tr)
            clean_en, ref_en = extract_trailing_reference(record.en, record.book_reference_en)
            record = replace(
                record,
                tr=clean_tr,
                en=clean_en,
                book_reference_tr=ref_tr,
                book_reference_en=ref_en,
            )
        record.duplicate_info = self.build_duplicate_info(record)
        record.updated_at = self._utc_now()
        if record.status == "approved" and not record.approved_at:
            record.approved_at = record.updated_at
        if not record.created_at:
            record.created_at = record.updated_at
        record.review_history.append(
            {
                "at": record.updated_at,
                "status": record.status,
                "priority": record.priority,
                "notes": record.notes,
            }
        )
        archive_backup = self._backup_and_assert_hash(self._archive_path(record.kind))
        payload = self._archive_payloads[record.kind]
        raw = apply_record_to_raw(record)
        self._upsert_payload_record(payload, raw, record)
        self._write_payload(payload["path"], payload["root"], record.kind == "approved")

        approved_backup: Path | None = None
        if record.status == "approved":
            approved_backup = self._backup_and_assert_hash(self._approved_path(record.kind))
            self._upsert_approved_record(record)
        else:
            approved_backup = self._backup_and_assert_hash(self._approved_path(record.kind))
            self._remove_approved_record(record.kind, record.id)

        self.state.last_undo = {
            "archive_target": str(self._archive_path(record.kind)),
            "archive_backup": str(archive_backup or ""),
            "approved_target": str(self._approved_path(record.kind)),
            "approved_backup": str(approved_backup or ""),
        }
        self._save_state()
        self.reload()
        self.logger.log("save_record", kind=record.kind, record_id=record.id, status=record.status)
        saved = self.find_archive_record(record.kind, record.id) or self.find_archive_record(record.kind, record.ref)
        if saved is None:
            raise RuntimeError("Kaydedilen kayit tekrar bulunamadi.")
        return saved

    def undo_last_write(self) -> bool:
        last = self.state.last_undo
        archive_target = Path(last.get("archive_target", "")) if last.get("archive_target") else None
        archive_backup = Path(last.get("archive_backup", "")) if last.get("archive_backup") else None
        approved_target = Path(last.get("approved_target", "")) if last.get("approved_target") else None
        approved_backup = Path(last.get("approved_backup", "")) if last.get("approved_backup") else None
        if not archive_target or not archive_backup or not archive_backup.exists():
            return False
        self.backup_manager.restore_backup(archive_backup, archive_target)
        if approved_target and approved_backup and approved_backup.exists():
            self.backup_manager.restore_backup(approved_backup, approved_target)
        self.logger.log("undo_last_write", archive_target=str(archive_target), approved_target=str(approved_target or ""))
        self.reload()
        return True

    def set_cursor(self, kind: ContentKind, value: int) -> None:
        self.state.cursors[kind] = max(0, int(value))
        self._save_state()

    def get_cursor(self, kind: ContentKind) -> int:
        return max(0, int(self.state.cursors.get(kind, 0)))

    def _parse_archive_record(
        self,
        kind: ContentKind,
        raw: dict[str, Any],
        path: Path,
        root_key: str,
        index: int,
    ) -> BaseRecord:
        ref = str(raw.get("ref") or raw.get("id") or "").strip()
        status = self._normalize_status(raw.get("status") or raw.get("review", {}).get("status"))
        priority = self._normalize_priority(raw.get("priority") or raw.get("review", {}).get("priority"))
        notes = str(raw.get("notes") or raw.get("review", {}).get("note") or "").strip()
        source_info = self._extract_source_info(raw)
        duplicate_info = self._extract_duplicate_info(raw)
        created_at = str(raw.get("createdAt") or raw.get("created_at") or "")
        updated_at = str(raw.get("updatedAt") or raw.get("updated_at") or raw.get("review", {}).get("updated_at") or "")
        approved_at = str(raw.get("approvedAt") or raw.get("approved_at") or "")
        location = ArchiveLocation(path=path, root_key=root_key, index=index)
        base_kwargs = dict(
            id=str(raw.get("id") or ref).strip(),
            kind=kind,
            ref=ref,
            ar=self._extract_text(raw, kind, "ar"),
            tr=self._extract_text(raw, kind, "tr"),
            en=self._extract_text(raw, kind, "en"),
            status=status,
            priority=priority,
            notes=notes,
            source_info=source_info,
            duplicate_info=duplicate_info,
            review_history=list(raw.get("reviewHistory") or []),
            created_at=created_at,
            updated_at=updated_at,
            approved_at=approved_at,
            raw=dict(raw),
            location=location,
        )
        if kind == "ayah":
            surah_number = self._safe_int(raw.get("surah_number") or raw.get("surah"))
            ayah_number = self._safe_int(raw.get("ayah_number") or raw.get("ayah") or self._extract_ayah_no_from_ref(ref))
            surah_name = str(raw.get("surah_name") or SURAH_NAMES_TR.get(surah_number or 0, "")).strip()
            return AyahRecord(**base_kwargs, surah_number=surah_number, ayah_number=ayah_number, surah_name=surah_name)
        hadith_number = self._safe_int(raw.get("hadith_number") or raw.get("hadithNo"))
        return HadithRecord(
            **base_kwargs,
            hadith_number=hadith_number,
            book_reference_tr=self._extract_book_reference(raw, "tr"),
            book_reference_en=self._extract_book_reference(raw, "en"),
        )

    def _parse_approved_record(self, kind: ContentKind, raw: dict[str, Any]) -> BaseRecord:
        approved = ApprovedRecord(
            id=str(raw.get("id") or "").strip(),
            kind=kind,
            ref=str(raw.get("ref") or "").strip(),
            ar=str(raw.get("ar") or "").strip(),
            tr=str(raw.get("tr") or "").strip(),
            en=str(raw.get("en") or "").strip(),
            priority=self._normalize_priority(raw.get("priority")),
            approved_at=str(raw.get("approvedAt") or "").strip(),
            surah_number=self._safe_int(raw.get("surah_number")),
            surah_name=str(raw.get("surah_name") or "").strip(),
            ayah_number=self._safe_int(raw.get("ayah_number")),
            hadith_number=self._safe_int(raw.get("hadith_number")),
            book_reference_tr=str(raw.get("book_reference_tr") or "").strip(),
            book_reference_en=str(raw.get("book_reference_en") or "").strip(),
        )
        validate_approved_record(approved)
        if kind == "ayah":
            return AyahRecord(
                id=approved.id,
                kind=kind,
                ref=approved.ref,
                ar=approved.ar,
                tr=approved.tr,
                en=approved.en,
                status="approved",
                priority=approved.priority,
                notes="",
                source_info=SourceInfo(label="approved_payload"),
                duplicate_info=DuplicateCheckResult(),
                review_history=[],
                created_at="",
                updated_at="",
                approved_at=approved.approved_at,
                surah_number=approved.surah_number or (self._safe_int(approved.ref.split("/")[0]) if "/" in approved.ref else None),
                ayah_number=approved.ayah_number or (self._safe_int(approved.ref.split("/")[1]) if "/" in approved.ref else None),
                surah_name=approved.surah_name,
            )
        return HadithRecord(
            id=approved.id,
            kind=kind,
            ref=approved.ref,
            ar=approved.ar,
            tr=approved.tr,
            en=approved.en,
            status="approved",
            priority=approved.priority,
            notes="",
            source_info=SourceInfo(label="approved_payload"),
            duplicate_info=DuplicateCheckResult(),
            review_history=[],
            created_at="",
            updated_at="",
            approved_at=approved.approved_at,
            hadith_number=approved.hadith_number or self._safe_int(approved.ref.split("/")[-1]),
            book_reference_tr=approved.book_reference_tr,
            book_reference_en=approved.book_reference_en,
        )

    @staticmethod
    def _extract_ayah_no_from_ref(ref: str) -> int | None:
        if "/" not in ref:
            return None
        try:
            return int(ref.split("/")[-1])
        except ValueError:
            return None

    def _extract_text(self, raw: dict[str, Any], kind: ContentKind, language: str) -> str:
        direct_key = f"text_{language}"
        direct_value = str(raw.get(direct_key) or "").strip()
        if direct_value:
            if kind == "hadith" and language in {"tr", "en"}:
                return extract_trailing_reference(direct_value, self._extract_book_reference(raw, language))[0]
            return direct_value
        if kind == "ayah":
            ayahs = raw.get("ayahs")
            if isinstance(ayahs, list):
                parts: list[str] = []
                for item in ayahs:
                    if not isinstance(item, dict):
                        continue
                    if language == "ar":
                        value = str(item.get("arabic") or "").strip()
                    else:
                        nested = item.get(language)
                        value = str(nested.get("text") if isinstance(nested, dict) else "").strip()
                    if value:
                        parts.append(value)
                return "\n\n".join(parts)
        text_obj = raw.get("text")
        if isinstance(text_obj, dict):
            lang_obj = text_obj.get(language)
            if isinstance(lang_obj, dict):
                value = str(lang_obj.get("clean") or lang_obj.get("sourceText") or "").strip()
                if kind == "hadith" and language in {"tr", "en"}:
                    return extract_trailing_reference(value, self._extract_book_reference(raw, language))[0]
                return value
        return ""

    def _extract_book_reference(self, raw: dict[str, Any], language: str) -> str:
        top_level = str(raw.get(f"book_reference_{language}") or "").strip()
        if top_level:
            return top_level
        source_info = raw.get("sourceInfo")
        if isinstance(source_info, dict):
            display = source_info.get("display")
            if isinstance(display, dict):
                return str(display.get(language) or "").strip()
        if language in {"tr", "en"}:
            return extract_trailing_reference(str(raw.get(f"text_{language}") or "").strip())[1]
        return ""

    def _extract_source_info(self, raw: dict[str, Any]) -> SourceInfo:
        source_info = raw.get("sourceInfo")
        if isinstance(source_info, dict):
            sunnah = source_info.get("sunnah")
            source_ref = ""
            if isinstance(sunnah, dict):
                source_ref = str(sunnah.get("candidateUrl") or "").strip()
            return SourceInfo(
                label=str(source_info.get("primaryCollection", {}).get("title_tr") if isinstance(source_info.get("primaryCollection"), dict) else source_info.get("label") or "").strip(),
                source_ref=source_ref,
                fetch_status=str(raw.get("sourceInfo", {}).get("fetch_status") or raw.get("status") or "").strip() or "loaded",
                details=source_info,
            )
        source = raw.get("source")
        label = ""
        if isinstance(source, dict):
            label = str(source.get("tr") or source.get("en") or source.get("arabic") or "").strip()
        source_ref = ""
        groups = raw.get("sourceRefGroups")
        if isinstance(groups, list) and groups:
            source_ref = str(groups[0]).strip()
        return SourceInfo(
            label=label,
            source_ref=source_ref,
            fetch_status="loaded",
            details={"source": source, "input": raw.get("input")},
        )

    def _extract_duplicate_info(self, raw: dict[str, Any]) -> DuplicateCheckResult:
        info = raw.get("duplicateInfo")
        if not isinstance(info, dict):
            return DuplicateCheckResult()
        return DuplicateCheckResult(
            exists_in_archive=bool(info.get("existsInArchive")),
            exists_in_approved=bool(info.get("existsInApproved")),
            exact_duplicate=bool(info.get("exactDuplicate")),
            possible_duplicate=bool(info.get("possibleDuplicate")),
            archive_matches=[DuplicateMatch(**row) for row in info.get("archiveMatches", []) if isinstance(row, dict)],
            approved_matches=[DuplicateMatch(**row) for row in info.get("approvedMatches", []) if isinstance(row, dict)],
        )

    def _upsert_payload_record(self, payload: dict[str, Any], raw: dict[str, Any], record: BaseRecord) -> None:
        rows = payload["records"]
        if record.location and record.location.path == payload["path"] and 0 <= record.location.index < len(rows):
            rows[record.location.index] = raw
            return
        for index, row in enumerate(rows):
            if not isinstance(row, dict):
                continue
            if str(row.get("id") or "").strip() == record.id:
                rows[index] = raw
                return
            if str(row.get("ref") or "").strip() == record.ref:
                rows[index] = raw
                return
        rows.append(raw)

    def _upsert_approved_record(self, record: BaseRecord) -> None:
        payload = self._approved_payloads[record.kind]
        approved = to_approved_record(record)
        validate_approved_record(approved)
        rows = payload["records"]
        raw = {
            "id": approved.id,
            "kind": approved.kind,
            "ref": approved.ref,
            "ar": approved.ar,
            "tr": approved.tr,
            "en": approved.en,
            "priority": approved.priority,
            "approvedAt": approved.approved_at,
        }
        if approved.kind == "ayah":
            raw["surah_number"] = approved.surah_number
            raw["surah_name"] = approved.surah_name
            raw["ayah_number"] = approved.ayah_number
        if approved.kind == "hadith":
            raw["hadith_number"] = approved.hadith_number
            raw["book_reference_tr"] = approved.book_reference_tr
            raw["book_reference_en"] = approved.book_reference_en
        replaced = False
        for index, row in enumerate(rows):
            if not isinstance(row, dict):
                continue
            if str(row.get("id") or "").strip() == approved.id:
                rows[index] = raw
                replaced = True
                break
        if not replaced:
            rows.append(raw)
        payload["root"]["content_version"] = f"tool-{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        payload["root"]["records"] = rows
        self._write_payload(payload["path"], payload["root"], is_approved=True)

    def _remove_approved_record(self, kind: ContentKind, record_id: str) -> None:
        payload = self._approved_payloads[kind]
        rows = [row for row in payload["records"] if str(row.get("id") or "").strip() != record_id]
        payload["records"] = rows
        payload["root"]["records"] = rows
        payload["root"]["content_version"] = f"tool-{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        self._write_payload(payload["path"], payload["root"], is_approved=True)

    def _load_state(self) -> ToolState:
        if not self.paths.state_path.exists():
            return ToolState()
        with self.paths.state_path.open("r", encoding="utf-8") as handle:
            data = json.load(handle)
        return ToolState(
            cursors=dict(data.get("cursors") or {"ayah": 0, "hadith": 0}),
            last_undo=dict(data.get("last_undo") or {}),
        )

    def _save_state(self) -> None:
        payload = {
            "cursors": self.state.cursors,
            "last_undo": self.state.last_undo,
        }
        self._atomic_json_write(self.paths.state_path, payload)
        self._hashes[self.paths.state_path] = self._file_hash(self.paths.state_path)

    def _read_payload(self, path: Path, default_type: str = "archive") -> dict[str, Any]:
        if not path.exists():
            path.parent.mkdir(parents=True, exist_ok=True)
            if default_type == "approved":
                kind = "ayah" if "ayah" in path.name else "hadith"
                root = {"schema_version": "1.0.0", "content_version": "tool-init", "type": kind, "records": []}
                self._atomic_json_write(path, root)
            else:
                root = {"metadata": {}, "items": []}
                self._atomic_json_write(path, root)
        with path.open("r", encoding="utf-8-sig") as handle:
            root = json.load(handle)
        self._hashes[path] = self._file_hash(path)
        if isinstance(root, list):
            return {"path": path, "root": root, "records": root, "root_key": "list"}
        if isinstance(root, dict):
            if isinstance(root.get("items"), list):
                return {"path": path, "root": root, "records": root["items"], "root_key": "items"}
            if isinstance(root.get("records"), list):
                return {"path": path, "root": root, "records": root["records"], "root_key": "records"}
        raise ValueError(f"Beklenen JSON yapi okunamadi: {path}")

    def _backup_and_assert_hash(self, path: Path) -> Path | None:
        current_hash = self._file_hash(path) if path.exists() else ""
        known_hash = self._hashes.get(path, current_hash)
        if current_hash != known_hash:
            raise StorageConflictError(f"Dosya disaridan degisti: {path}")
        return self.backup_manager.create_backup(path)

    def _write_payload(self, path: Path, root: Any, is_approved: bool) -> None:
        self._atomic_json_write(path, root)
        self._hashes[path] = self._file_hash(path)
        if is_approved:
            self._approved_payloads["ayah" if "ayah" in path.name else "hadith"] = self._read_payload(path, default_type="approved")
        else:
            self._archive_payloads["ayah" if "ayah" in path.name else "hadith"] = self._read_payload(path)

    @staticmethod
    def _atomic_json_write(path: Path, data: Any) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        tmp = path.with_suffix(path.suffix + ".tmp")
        with tmp.open("w", encoding="utf-8", newline="\n") as handle:
            json.dump(data, handle, ensure_ascii=False, indent=2)
            handle.write("\n")
        tmp.replace(path)

    @staticmethod
    def _file_hash(path: Path) -> str:
        if not path.exists():
            return ""
        digest = hashlib.sha256()
        with path.open("rb") as handle:
            for chunk in iter(lambda: handle.read(65536), b""):
                digest.update(chunk)
        return digest.hexdigest()

    @staticmethod
    def _safe_int(value: Any) -> int | None:
        try:
            if value is None or value == "":
                return None
            return int(value)
        except (TypeError, ValueError):
            return None

    @staticmethod
    def _normalize_priority(value: Any) -> int:
        if isinstance(value, dict):
            value = value.get("priority")
        try:
            parsed = int(value)
        except (TypeError, ValueError):
            return 3
        return parsed if parsed in {1, 2, 3, 4, 5} else 3

    @staticmethod
    def _normalize_status(value: Any) -> str:
        raw = str(value or "").strip().lower()
        mapping = {
            "pending_review": "needs_review",
            "pending": "needs_review",
            "backlog": "archived",
            "rejected": "rejected",
            "approved": "approved",
            "needs_review": "needs_review",
            "draft": "draft",
            "fetched": "fetched",
            "needs_translation": "needs_translation",
            "needs_source_check": "needs_source_check",
            "duplicate": "duplicate",
            "archived": "archived",
        }
        return mapping.get(raw, "needs_review")

    @staticmethod
    def _archive_path(kind: ContentKind) -> Path:
        raise RuntimeError("instance method expected")

    @staticmethod
    def _approved_path(kind: ContentKind) -> Path:
        raise RuntimeError("instance method expected")

    def _archive_path(self, kind: ContentKind) -> Path:
        return self.paths.archive_ayah_path if kind == "ayah" else self.paths.archive_hadith_path

    def _approved_path(self, kind: ContentKind) -> Path:
        return self.paths.approved_ayah_path if kind == "ayah" else self.paths.approved_hadith_path

    @staticmethod
    def _utc_now() -> str:
        return datetime.now(timezone.utc).replace(microsecond=0).isoformat()
