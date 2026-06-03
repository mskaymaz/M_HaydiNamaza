from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Literal

ContentKind = Literal["ayah", "hadith"]

STATUS_VALUES = (
    "draft",
    "fetched",
    "needs_review",
    "needs_translation",
    "needs_source_check",
    "approved",
    "rejected",
    "duplicate",
    "archived",
)

PRIORITY_VALUES = (1, 2, 3)


@dataclass(slots=True)
class AppPaths:
    repo_root: Path
    tool_root: Path
    archive_ayah_path: Path
    archive_hadith_path: Path
    approved_ayah_path: Path
    approved_hadith_path: Path
    state_path: Path
    log_path: Path
    backup_dir: Path


@dataclass(slots=True)
class SourceInfo:
    label: str = ""
    source_ref: str = ""
    fetch_status: str = "not_requested"
    details: dict[str, Any] = field(default_factory=dict)


@dataclass(slots=True)
class DuplicateMatch:
    record_id: str
    reason: str
    score: float = 1.0
    ref: str = ""


@dataclass(slots=True)
class DuplicateCheckResult:
    exists_in_archive: bool = False
    exists_in_approved: bool = False
    exact_duplicate: bool = False
    possible_duplicate: bool = False
    archive_matches: list[DuplicateMatch] = field(default_factory=list)
    approved_matches: list[DuplicateMatch] = field(default_factory=list)


@dataclass(slots=True)
class ArchiveLocation:
    path: Path
    root_key: str
    index: int


@dataclass(slots=True)
class BaseRecord:
    id: str
    kind: ContentKind
    ref: str
    ar: str
    tr: str
    en: str
    status: str
    priority: int
    notes: str
    source_info: SourceInfo
    duplicate_info: DuplicateCheckResult
    review_history: list[dict[str, Any]]
    created_at: str
    updated_at: str
    approved_at: str
    raw: dict[str, Any] = field(default_factory=dict)
    location: ArchiveLocation | None = None


@dataclass(slots=True)
class AyahRecord(BaseRecord):
    surah_number: int | None = None
    ayah_number: int | None = None
    surah_name: str = ""


@dataclass(slots=True)
class HadithRecord(BaseRecord):
    hadith_number: int | None = None
    book_reference_tr: str = ""
    book_reference_en: str = ""


@dataclass(slots=True)
class ApprovedRecord:
    id: str
    kind: ContentKind
    ref: str
    ar: str
    tr: str
    en: str
    priority: int
    approved_at: str
    surah_number: int | None = None
    surah_name: str = ""
    ayah_number: int | None = None
    hadith_number: int | None = None
    book_reference_tr: str = ""
    book_reference_en: str = ""


@dataclass(slots=True)
class FetchResult:
    success: bool
    status_label: str
    source_info: SourceInfo
    ar: str = ""
    tr: str = ""
    en: str = ""
    extra: dict[str, Any] = field(default_factory=dict)
    error: str = ""


@dataclass(slots=True)
class ToolState:
    cursors: dict[str, int] = field(default_factory=lambda: {"ayah": 0, "hadith": 0})
    last_undo: dict[str, str] = field(default_factory=dict)
