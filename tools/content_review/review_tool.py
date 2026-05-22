#!/usr/bin/env python3
"""Local-only desktop review tool for ayah/hadith draft content (PySide6)."""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Optional

try:
    from PySide6.QtCore import QTimer, Qt
    from PySide6.QtGui import QFont, QTextOption
    from PySide6.QtWidgets import (
        QApplication,
        QCheckBox,
        QComboBox,
        QFormLayout,
        QGridLayout,
        QGroupBox,
        QHBoxLayout,
        QLineEdit,
        QLabel,
        QMainWindow,
        QMessageBox,
        QPushButton,
        QSplitter,
        QTextEdit,
        QVBoxLayout,
        QWidget,
    )
except ImportError:
    print("PySide6 not found.")
    print("Install command: py -m pip install PySide6")
    raise SystemExit(1)


VALID_STATUSES = {"approved", "backlog", "pending"}
VALID_PRIORITIES = {"normal", "important", "high", "seasonal", "hidden"}
PRIORITY_LABELS_TR = {
    "normal": "Normal gosterim",
    "important": "Daha sik goster",
    "high": "Cok daha sik goster",
    "seasonal": "Belirli donemlerde one cikar",
    "hidden": "Simdilik gosterme",
}
PRIORITY_EXPORT_MAP = {
    "normal": {"priority": 1, "boost_enabled": False, "boost_weight": 1},
    "important": {"priority": 2, "boost_enabled": True, "boost_weight": 2},
    "high": {"priority": 3, "boost_enabled": True, "boost_weight": 3},
    "seasonal": {"priority": 2, "boost_enabled": True, "boost_weight": 2},
    "hidden": {"priority": 0, "boost_enabled": False, "boost_weight": 1},
}


def _normalize_priority(value: Any) -> str:
    raw = str(value or "").strip().lower()
    if raw in VALID_PRIORITIES:
        return raw
    return "normal"


@dataclass(frozen=True)
class InputConfig:
    ayah_path: Path
    hadith_path: Path


class ReviewStore:
    def __init__(
        self,
        root: Path,
        inputs: InputConfig,
        state_path: Path,
        dataset_filter: str = "all",
    ) -> None:
        self.root = root
        self.inputs = inputs
        self.state_path = state_path
        self.output_dir = root / "output"
        self.output_dir.mkdir(parents=True, exist_ok=True)

        self._dataset_filter = self._normalize_dataset_filter(dataset_filter)

        self._dataset_paths = {
            "ayah": inputs.ayah_path,
            "hadith": inputs.hadith_path,
        }
        self._roots: dict[str, Any] = {}
        self._records_by_dataset: dict[str, list[dict[str, Any]]] = {}
        self._root_is_list: dict[str, bool] = {}
        self._backups_done: set[Path] = set()

        ayah_root, ayah_records, ayah_is_list = self._read_json_payload(inputs.ayah_path)
        hadith_root, hadith_records, hadith_is_list = self._read_json_payload(inputs.hadith_path)
        self._roots["ayah"] = ayah_root
        self._roots["hadith"] = hadith_root
        self._records_by_dataset["ayah"] = ayah_records
        self._records_by_dataset["hadith"] = hadith_records
        self._root_is_list["ayah"] = ayah_is_list
        self._root_is_list["hadith"] = hadith_is_list

        self._all_records: list[dict[str, Any]] = []
        for idx, rec in enumerate(ayah_records):
            self._all_records.append(self._normalize_record(rec, "ayah", idx))
        for idx, rec in enumerate(hadith_records):
            self._all_records.append(self._normalize_record(rec, "hadith", idx))

        if not self._all_records:
            raise RuntimeError("No records found in input files.")

        self.state = self._load_or_init_state()
        self._apply_dataset_filter(self._dataset_filter, save_state=False)
        self._save_state()

    @staticmethod
    def _normalize_dataset_filter(value: str) -> str:
        raw = str(value or "").strip().lower()
        if raw in {"all", "ayah", "hadith"}:
            return raw
        return "all"

    def set_dataset_filter(self, dataset_filter: str) -> None:
        new_filter = self._normalize_dataset_filter(dataset_filter)
        if new_filter == self._dataset_filter:
            return
        self._dataset_filter = new_filter
        self._apply_dataset_filter(new_filter, save_state=True)

    def get_dataset_filter(self) -> str:
        return self._dataset_filter

    def _apply_dataset_filter(self, dataset_filter: str, save_state: bool) -> None:
        if dataset_filter == "all":
            self.records = list(self._all_records)
        else:
            self.records = [r for r in self._all_records if str(r.get("_dataset", "")) == dataset_filter]

        self.state.setdefault("cursors", {"all": 0, "ayah": 0, "hadith": 0})
        cursors = self.state.get("cursors")
        if not isinstance(cursors, dict):
            cursors = {"all": 0, "ayah": 0, "hadith": 0}
            self.state["cursors"] = cursors
        for key in ("all", "ayah", "hadith"):
            if key not in cursors:
                cursors[key] = 0

        cursor = int(cursors.get(dataset_filter, 0) or 0)
        cursor = max(0, min(cursor, len(self.records) - 1))
        cursors[dataset_filter] = cursor
        if save_state:
            self._save_state()

    @staticmethod
    def _read_json_payload(path: Path) -> tuple[Any, list[dict[str, Any]], bool]:
        # utf-8-sig handles both BOM and non-BOM UTF-8 safely.
        with path.open("r", encoding="utf-8-sig") as f:
            data = json.load(f)
        if isinstance(data, list):
            return data, data, True
        if isinstance(data, dict) and isinstance(data.get("records"), list):
            return data, data["records"], False
        raise ValueError(f"Expected JSON array or object with records[] in {path}")

    @staticmethod
    def _normalize_record(record: dict[str, Any], dataset: str, record_index: int) -> dict[str, Any]:
        if "id" not in record:
            raise ValueError(f"Record missing id in dataset={dataset}")
        out = dict(record)
        out["_dataset"] = dataset
        out["_record_index"] = record_index
        out["_record_key"] = f"{dataset}:{record['id']}"
        return out

    def _persist_dataset(self, dataset: str) -> None:
        path = self._dataset_paths[dataset]
        self._ensure_backup(path)
        if self._root_is_list[dataset]:
            payload = self._records_by_dataset[dataset]
        else:
            root_obj = self._roots[dataset]
            root_obj["records"] = self._records_by_dataset[dataset]
            payload = root_obj
        self._atomic_json_write(path, payload)

    def _ensure_backup(self, path: Path) -> None:
        if path in self._backups_done:
            return
        if not path.exists():
            return
        ts = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_path = path.with_suffix(path.suffix + f".bak.{ts}")
        try:
            shutil.copy2(path, backup_path)
        finally:
            self._backups_done.add(path)

    @staticmethod
    def _extract_trailing_book_ref(text_tr: str, existing_ref: str) -> tuple[str, str]:
        work = str(text_tr or "")
        refs: list[str] = []
        if str(existing_ref or "").strip():
            refs.append(str(existing_ref).strip())
        ref_cue = (
            "Buhar|Bukhari|Müslim|Muslim|Tirmiz|Tirmizî|Nesai|Nesa'i|"
            "Ebû|Ebu|Dâv|Dav|Dawud|Mâce|Mace|İM|IM|Ahmed|Darimi|Dârim|"
            "Bkz|bkz|B\\d|M\\d|T\\d|D\\d"
        )
        while True:
            m = re.match(
                r'(?s)^(.*?)(\s*([\(\[])([^()\[\]]*)([\)\]])\s*[\.\!؟،»"]?\s*)$',
                work,
            )
            if not m:
                break
            inside = (m.group(4) or "").strip()
            if not inside:
                break
            if not re.search(ref_cue, inside):
                break
            tail = (m.group(2) or "").strip()
            tail = re.sub(r'[\.\!؟،»"]\s*$', "", tail).strip()
            if tail.startswith("[") and tail.endswith("]"):
                tail = "(" + tail[1:-1].strip() + ")"
            if tail and tail not in refs:
                refs.append(tail)
            work = (m.group(1) or "").rstrip()
        return work, "; ".join(refs).strip()

    @staticmethod
    def _detect_trailing_book_ref_tails(text_tr: str) -> list[str]:
        work = str(text_tr or "")
        tails: list[str] = []
        ref_cue = (
            "Buhar|Bukhari|Müslim|Muslim|Tirmiz|Tirmizî|Nesai|Nesa'i|"
            "Ebû|Ebu|Dâv|Dav|Dawud|Mâce|Mace|İM|IM|Ahmed|Darimi|Dârim|"
            "Bkz|bkz|B\\d|M\\d|T\\d|D\\d"
        )
        while True:
            m = re.match(
                r'(?s)^(.*?)(\s*([\(\[])([^()\[\]]*)([\)\]])\s*[\.\!؟،»"]?\s*)$',
                work,
            )
            if not m:
                break
            inside = (m.group(4) or "").strip()
            if not inside:
                break
            if not re.search(ref_cue, inside):
                break
            tail = (m.group(2) or "").strip()
            tail = re.sub(r'[\.\!؟،»"]\s*$', "", tail).strip()
            if tail.startswith("[") and tail.endswith("]"):
                tail = "(" + tail[1:-1].strip() + ")"
            if tail:
                tails.append(tail)
            work = (m.group(1) or "").rstrip()
        return tails

    def _load_or_init_state(self) -> dict[str, Any]:
        now = self._utc_now()
        if self.state_path.exists():
            with self.state_path.open("r", encoding="utf-8") as f:
                state = json.load(f)
            if not isinstance(state, dict):
                raise ValueError("review_state.json must be an object.")
        else:
            state = {
                "version": 1,
                "created_at": now,
                "updated_at": now,
                "cursor": 0,
                "cursors": {"all": 0, "ayah": 0, "hadith": 0},
                "input_files": {
                    "ayah": str(self.inputs.ayah_path),
                    "hadith": str(self.inputs.hadith_path),
                },
                "decisions": {},
            }

        state.setdefault("version", 1)
        state.setdefault("created_at", now)
        state.setdefault("updated_at", now)
        state.setdefault("cursor", 0)
        state.setdefault("cursors", {"all": int(state.get("cursor", 0) or 0), "ayah": 0, "hadith": 0})
        state.setdefault("input_files", {})
        state.setdefault("decisions", {})

        # Backwards compatibility: old state used a single cursor over the full list.
        cursors = state.get("cursors")
        if not isinstance(cursors, dict):
            cursors = {"all": int(state.get("cursor", 0) or 0), "ayah": 0, "hadith": 0}
            state["cursors"] = cursors
        for key in ("all", "ayah", "hadith"):
            if key not in cursors:
                cursors[key] = 0
        state["cursor"] = max(0, int(state.get("cursor", 0) or 0))
        return state

    @staticmethod
    def _utc_now() -> str:
        return datetime.now(timezone.utc).replace(microsecond=0).isoformat()

    def _save_state(self) -> None:
        self.state["updated_at"] = self._utc_now()
        self._atomic_json_write(self.state_path, self.state)

    @staticmethod
    def _atomic_json_write(path: Path, data: Any) -> None:
        tmp = path.with_suffix(path.suffix + ".tmp")
        with tmp.open("w", encoding="utf-8", newline="\n") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            f.write("\n")
        os.replace(tmp, path)

    def summary(self) -> dict[str, int]:
        totals = {"approved": 0, "backlog": 0, "pending": 0}
        for rec in self.records:
            status = str(rec.get("status", "pending") or "pending").strip().lower()
            if status == "rejected":
                status = "backlog"
            if status not in VALID_STATUSES:
                status = "pending"
            totals[status] += 1
        return totals

    def current_payload(self) -> dict[str, Any]:
        cursors = self.state.get("cursors", {})
        cursor = int((cursors.get(self._dataset_filter, 0) if isinstance(cursors, dict) else 0) or 0)
        cursor = max(0, min(cursor, len(self.records) - 1))
        rec = self.records[cursor]
        decisions = self.state.get("decisions", {})
        raw_decision = decisions.get(rec["_record_key"], {})
        status = str(rec.get("status", "pending") or "pending").strip().lower()
        if status == "rejected":
            status = "backlog"
        if status not in VALID_STATUSES:
            status = "pending"
        current_decision = {
            "status": status,
            "note": raw_decision.get("note", ""),
            "priority": _normalize_priority(raw_decision.get("priority", "normal")),
            "boost_start_date": str(raw_decision.get("boost_start_date", "") or ""),
            "boost_end_date": str(raw_decision.get("boost_end_date", "") or ""),
            "updated_at": raw_decision.get("updated_at", "-"),
        }
        return {
            "cursor": cursor,
            "total": len(self.records),
            "record": rec,
            "decision": current_decision,
            "summary": self.summary(),
            "dataset_filter": self._dataset_filter,
        }

    def move_cursor(self, direction: str) -> dict[str, Any]:
        cursors = self.state.get("cursors", {})
        cursor = int((cursors.get(self._dataset_filter, 0) if isinstance(cursors, dict) else 0) or 0)
        if direction == "next":
            cursor = min(cursor + 1, len(self.records) - 1)
        elif direction == "prev":
            cursor = max(cursor - 1, 0)
        elif direction == "first":
            cursor = 0
        elif direction == "last":
            cursor = len(self.records) - 1
        else:
            raise ValueError("Invalid direction.")
        self.state["cursor"] = cursor
        if isinstance(cursors, dict):
            cursors[self._dataset_filter] = cursor
        self._save_state()
        return self.current_payload()

    def save_current(
        self,
        status: str,
        text_tr: str,
        text_ar: str,
        text_en: str,
        book_reference_tr: str = "",
        note: str = "",
        priority: str = "normal",
        move_next: bool = False,
    ) -> dict[str, Any]:
        if status not in VALID_STATUSES:
            raise ValueError("Invalid status.")
        if priority not in VALID_PRIORITIES:
            raise ValueError("Invalid priority.")
        cursors = self.state.get("cursors", {})
        cursor = int((cursors.get(self._dataset_filter, 0) if isinstance(cursors, dict) else 0) or 0)
        cursor = max(0, min(cursor, len(self.records) - 1))
        rec = self.records[cursor]
        dataset = str(rec.get("_dataset", ""))
        rec_index = int(rec.get("_record_index", 0))
        base_record = self._records_by_dataset[dataset][rec_index]
        key = rec["_record_key"]
        previous = self.state["decisions"].get(key, {})
        clean_tr = str(text_tr or "")
        clean_book_ref = str(book_reference_tr or "")
        if dataset == "hadith":
            clean_tr, clean_book_ref = self._extract_trailing_book_ref(clean_tr, clean_book_ref)
            base_record["book_reference_tr"] = clean_book_ref
            rec["book_reference_tr"] = clean_book_ref
        base_record["text_tr"] = clean_tr
        base_record["text_ar"] = str(text_ar or "")
        base_record["text_en"] = str(text_en or "")
        base_record["status"] = status
        rec["text_tr"] = clean_tr
        rec["text_ar"] = str(text_ar or "")
        rec["text_en"] = str(text_en or "")
        rec["status"] = status
        self._persist_dataset(dataset)
        self.state["decisions"][key] = {
            "status": status,
            "note": note,
            "priority": priority,
            "boost_start_date": str(previous.get("boost_start_date", "") or ""),
            "boost_end_date": str(previous.get("boost_end_date", "") or ""),
            "updated_at": self._utc_now(),
        }
        if move_next:
            next_cursor = min(cursor + 1, len(self.records) - 1)
            self.state["cursor"] = next_cursor
            if isinstance(cursors, dict):
                cursors[self._dataset_filter] = next_cursor
        self._save_state()
        return self.current_payload()

    def jump_to_record(self, record_id: str, dataset: str = "all") -> Optional[dict[str, Any]]:
        target = str(record_id or "").strip()
        if not target:
            return None
        dataset_key = str(dataset or "all").strip().lower()
        for idx, rec in enumerate(self.records):
            if str(rec.get("id", "")).strip() != target:
                continue
            rec_dataset = str(rec.get("_dataset", "")).strip().lower()
            if dataset_key != "all" and rec_dataset != dataset_key:
                continue
            self.state["cursor"] = idx
            cursors = self.state.get("cursors")
            if isinstance(cursors, dict):
                cursors[self._dataset_filter] = idx
            self._save_state()
            return self.current_payload()
        return None

    def move_to_next_status(self, status: str) -> Optional[dict[str, Any]]:
        if status not in VALID_STATUSES:
            raise ValueError("Invalid status.")
        cursors = self.state.get("cursors", {})
        current = int((cursors.get(self._dataset_filter, 0) if isinstance(cursors, dict) else 0) or 0)
        decisions = self.state.get("decisions", {})
        for idx in range(current + 1, len(self.records)):
            rec = self.records[idx]
            key = rec["_record_key"]
            rec_status = str(rec.get("status", "pending") or "pending").strip().lower()
            if rec_status == "rejected":
                rec_status = "backlog"
            if rec_status == status:
                self.state["cursor"] = idx
                if isinstance(cursors, dict):
                    cursors[self._dataset_filter] = idx
                self._save_state()
                return self.current_payload()
        return None

    def export(self) -> dict[str, str]:
        ts = datetime.now().strftime("%Y%m%d_%H%M%S")
        target = self.output_dir / f"review_export_{ts}"
        if target.exists():
            suffix = 1
            while (self.output_dir / f"review_export_{ts}_{suffix}").exists():
                suffix += 1
            target = self.output_dir / f"review_export_{ts}_{suffix}"
        target.mkdir(parents=False, exist_ok=False)

        decisions = self.state.get("decisions", {})
        buckets: dict[str, list[dict[str, Any]]] = {
            "approved": [],
            "backlog": [],
            "pending": [],
        }

        for rec in self.records:
            key = rec["_record_key"]
            decision = decisions.get(key, {})
            status = decision.get("status", "pending")
            if status == "rejected":
                status = "backlog"
            if status not in VALID_STATUSES:
                status = "pending"
            priority_key = _normalize_priority(decision.get("priority", "normal"))
            mapped = PRIORITY_EXPORT_MAP[priority_key]
            clean_record = {k: v for k, v in rec.items() if not k.startswith("_")}
            clean_record["review_status"] = status
            clean_record["priority"] = mapped["priority"]
            clean_record["boost"] = {
                "enabled": mapped["boost_enabled"],
                "weight": mapped["boost_weight"],
            }
            if priority_key == "seasonal":
                clean_record["boost_start_date"] = str(
                    decision.get("boost_start_date", "") or ""
                )
                clean_record["boost_end_date"] = str(
                    decision.get("boost_end_date", "") or ""
                )
            if decision.get("note"):
                clean_record["review_note"] = decision["note"]
            buckets[status].append(clean_record)

        approved_path = target / "approved.json"
        rejected_path = target / "rejected.json"
        pending_path = target / "pending.json"
        decisions_path = target / "review_decisions.json"

        self._atomic_json_write(approved_path, buckets["approved"])
        # Backwards-compatible: backlog bucket is written to rejected.json
        self._atomic_json_write(rejected_path, buckets["backlog"])
        self._atomic_json_write(pending_path, buckets["pending"])
        self._atomic_json_write(
            decisions_path,
            {
                "exported_at": self._utc_now(),
                "state_file": str(self.state_path),
                "input_files": self.state.get("input_files", {}),
                "summary": self.summary(),
                "decisions": decisions,
            },
        )

        return {
            "directory": str(target),
            "approved": str(approved_path),
            "rejected": str(rejected_path),
            "pending": str(pending_path),
            "decisions": str(decisions_path),
        }


def _extract_record_view(rec: dict[str, Any]) -> dict[str, str]:
    dataset = str(rec.get("_dataset", ""))
    view: dict[str, str] = {
        "record_type": "Ayet" if dataset == "ayah" else "Hadis",
        "id": str(rec.get("id", "-")),
        "technical": "-",
        "source": str(rec.get("source_note", "-")),
        "tr_text": "-",
        "ar_text": "-",
        "en_text": "-",
    }

    if dataset == "ayah":
        surah_name = str(rec.get("surah_name", "-"))
        surah_number = str(rec.get("surah_number", "-"))
        ayah_number = str(rec.get("ayah_number", "-"))
        view["technical"] = (
            f"Sure: {surah_name} ({surah_number}) | Ayet No: {ayah_number}"
        )
        translation = rec.get("translation", {}) if isinstance(rec.get("translation"), dict) else {}
        text_obj = rec.get("text", {}) if isinstance(rec.get("text"), dict) else {}
        view["tr_text"] = str(rec.get("text_tr", translation.get("tr", "-")))
        view["ar_text"] = str(rec.get("text_ar", text_obj.get("ar", "-")))
        view["en_text"] = str(rec.get("text_en", translation.get("en", "-")))
    else:
        collection = str(rec.get("collection_name_tr", rec.get("collection_slug", "-")))
        hadith_number = str(rec.get("hadith_number", "-"))
        reference = str(rec.get("reference", "-"))
        narrator = str(rec.get("narrator", "-"))
        view["technical"] = (
            f"Koleksiyon: {collection} | Hadis No: {hadith_number} | Referans: {reference} | Ravi: {narrator}"
        )
        view["tr_text"] = str(rec.get("text_tr", "-"))
        view["ar_text"] = str(rec.get("text_ar", "-"))
        view["en_text"] = str(rec.get("text_en", "-"))
    return view


def _english_caps_warning(text: str) -> str:
    letters = [c for c in text if c.isalpha() and c.isascii()]
    if len(letters) < 40:
        return ""
    upper = sum(1 for c in letters if c.isupper())
    ratio = upper / len(letters) if letters else 0.0
    if ratio >= 0.40:
        return "Ingilizce metinde gereksiz BUYUK HARF yogunlugu olabilir. Kontrol ediniz."
    return ""


class ReviewWindow(QMainWindow):
    def __init__(self, store: ReviewStore) -> None:
        super().__init__()
        self.store = store
        self._selected_status = "pending"
        self._suspend_autosave = False
        self._autosave_timer = QTimer(self)
        self._autosave_timer.setSingleShot(True)
        self._autosave_timer.setInterval(700)
        self._autosave_timer.timeout.connect(self._autosave_now)
        self.setWindowTitle("Daily Content Review - PySide6")
        self.resize(1080, 700)
        self.setMinimumSize(900, 600)
        self._build_ui()
        self.refresh()

    def _build_ui(self) -> None:
        central = QWidget()
        root_layout = QVBoxLayout(central)
        self.setCentralWidget(central)

        top_box = QGroupBox("Ozet ve Gezinme")
        top_layout = QGridLayout(top_box)
        self.summary_label = QLabel("-")
        summary_line = QHBoxLayout()
        summary_line.addWidget(self.summary_label, 1)
        summary_line.addWidget(QLabel("Grup:"))
        self.dataset_filter_combo = QComboBox()
        self.dataset_filter_combo.addItem("Tumu", "all")
        self.dataset_filter_combo.addItem("Ayetler", "ayah")
        self.dataset_filter_combo.addItem("Hadisler", "hadith")
        self.dataset_filter_combo.currentIndexChanged.connect(self._on_dataset_filter_changed)
        summary_line.addWidget(self.dataset_filter_combo)
        top_layout.addLayout(summary_line, 0, 0, 1, 3)

        self.btn_first = QPushButton("Ilk")
        self.btn_prev = QPushButton("Onceki")
        self.btn_next = QPushButton("Sonraki")
        self.btn_last = QPushButton("Son")
        self.btn_export = QPushButton("Cikti Uret")
        self.btn_next_pending = QPushButton("Sonraki Pending")
        self.btn_first.clicked.connect(lambda: self._navigate("first"))
        self.btn_prev.clicked.connect(lambda: self._navigate("prev"))
        self.btn_next.clicked.connect(lambda: self._navigate("next"))
        self.btn_last.clicked.connect(lambda: self._navigate("last"))
        self.btn_export.clicked.connect(self._export)
        self.btn_next_pending.clicked.connect(self._next_pending)
        nav_line = QHBoxLayout()
        nav_line.addWidget(self.btn_first)
        nav_line.addWidget(self.btn_prev)
        nav_line.addWidget(self.btn_next)
        nav_line.addWidget(self.btn_last)
        nav_line.addStretch(1)
        nav_line.addWidget(self.btn_next_pending)
        nav_line.addWidget(self.btn_export)
        top_layout.addLayout(nav_line, 1, 0, 1, 3)

        jump_line = QHBoxLayout()
        self.jump_dataset = QComboBox()
        self.jump_dataset.addItem("Tum kayitlar", "all")
        self.jump_dataset.addItem("Sadece ayet", "ayah")
        self.jump_dataset.addItem("Sadece hadis", "hadith")
        self.jump_id = QLineEdit()
        self.jump_id.setPlaceholderText("ID yaz ve git (or: hadith-riyadussalihin-341)")
        self.btn_jump = QPushButton("ID'ye Git")
        self.btn_jump.clicked.connect(self._jump_to_id)
        jump_line.addWidget(self.jump_dataset)
        jump_line.addWidget(self.jump_id, 1)
        jump_line.addWidget(self.btn_jump)
        top_layout.addLayout(jump_line, 2, 0, 1, 3)
        root_layout.addWidget(top_box)

        splitter = QSplitter(Qt.Orientation.Horizontal)

        left_panel = QWidget()
        left_layout = QVBoxLayout(left_panel)
        self.record_title = QLabel("-")
        title_font = QFont()
        title_font.setPointSize(12)
        title_font.setBold(True)
        self.record_title.setFont(title_font)
        self.record_meta = QLabel("-")
        left_layout.addWidget(self.record_title)
        left_layout.addWidget(self.record_meta)

        info_box = QGroupBox("Teknik Bilgi")
        info_grid = QGridLayout(info_box)
        self.info_type = QLabel("-")
        self.info_id = QLabel("-")
        self.info_technical = QLabel("-")
        self.info_source = QLabel("-")
        self.info_technical.setWordWrap(True)
        self.info_source.setWordWrap(True)
        info_grid.addWidget(QLabel("Tur:"), 0, 0)
        info_grid.addWidget(self.info_type, 0, 1)
        info_grid.addWidget(QLabel("Kayit ID:"), 0, 2)
        info_grid.addWidget(self.info_id, 0, 3)
        info_grid.addWidget(QLabel("Bilgi:"), 1, 0)
        info_grid.addWidget(self.info_technical, 1, 1, 1, 3)
        info_grid.addWidget(QLabel("Kaynak Notu:"), 2, 0)
        info_grid.addWidget(self.info_source, 2, 1, 1, 3)
        left_layout.addWidget(info_box)

        lang_splitter = QSplitter(Qt.Orientation.Vertical)
        tr_box = QGroupBox("Turkce Metin")
        tr_layout = QVBoxLayout(tr_box)
        self.tr_text = QTextEdit()
        self._configure_flow_text(self.tr_text, extra_pt=2)
        self.tr_text.textChanged.connect(self._on_tr_text_changed)
        tr_layout.addWidget(self.tr_text)
        self.tr_ref_preview = QLabel("")
        self.tr_ref_preview.setWordWrap(True)
        self.tr_ref_preview.setStyleSheet("color:#555;")
        tr_layout.addWidget(self.tr_ref_preview)

        ar_box = QGroupBox("Arapca Metin")
        ar_layout = QVBoxLayout(ar_box)
        self.ar_text = QTextEdit()
        self._configure_flow_text(self.ar_text, extra_pt=2)
        self.ar_text.textChanged.connect(self._schedule_autosave)
        ar_layout.addWidget(self.ar_text)

        en_box = QGroupBox("Ingilizce Metin")
        en_layout = QVBoxLayout(en_box)
        self.en_text = QTextEdit()
        self._configure_flow_text(self.en_text)
        self.en_text.textChanged.connect(self._schedule_autosave)
        self.en_warning = QLabel("")
        self.en_warning.setStyleSheet("color:#b23b3b;")
        self.en_warning.setWordWrap(True)
        en_layout.addWidget(self.en_text)
        en_layout.addWidget(self.en_warning)
        self.book_ref_edit = QLineEdit()
        self.book_ref_edit.setPlaceholderText("Hadis referansi (book_reference_tr)")
        self.book_ref_edit.textChanged.connect(self._on_book_ref_changed)
        en_layout.addWidget(QLabel("Hadis Referans (book_reference_tr)"))
        en_layout.addWidget(self.book_ref_edit)

        lang_splitter.addWidget(tr_box)
        lang_splitter.addWidget(ar_box)
        lang_splitter.addWidget(en_box)
        lang_splitter.setStretchFactor(0, 3)
        lang_splitter.setStretchFactor(1, 3)
        lang_splitter.setStretchFactor(2, 3)
        left_layout.addWidget(lang_splitter, 1)

        right_panel = QWidget()
        right_layout = QVBoxLayout(right_panel)

        decision_box = QGroupBox("Inceleme")
        decision_layout = QVBoxLayout(decision_box)
        btn_line = QHBoxLayout()
        self.btn_approved = QPushButton("Onaylandi")
        self.btn_rejected = QPushButton("Arkaya At")
        self.btn_pending = QPushButton("Beklet")
        self.btn_approved.setStyleSheet("background:#eaf8ef;border:1px solid #6dbd7f;")
        self.btn_rejected.setStyleSheet("background:#fff1f1;border:1px solid #e59a9a;")
        self.btn_pending.setStyleSheet("background:#fff9ee;border:1px solid #d4b16a;")
        self.btn_approved.clicked.connect(lambda: self._set_status("approved"))
        self.btn_rejected.clicked.connect(lambda: self._set_status("backlog"))
        self.btn_pending.clicked.connect(lambda: self._set_status("pending"))
        btn_line.addWidget(self.btn_approved)
        btn_line.addWidget(self.btn_rejected)
        btn_line.addWidget(self.btn_pending)
        decision_layout.addLayout(btn_line)
        priority_line = QHBoxLayout()
        priority_line.addWidget(QLabel("Oncelik:"))
        self.priority_combo = QComboBox()
        self.priority_combo.addItem(PRIORITY_LABELS_TR["normal"], "normal")
        self.priority_combo.addItem(PRIORITY_LABELS_TR["important"], "important")
        self.priority_combo.addItem(PRIORITY_LABELS_TR["high"], "high")
        self.priority_combo.addItem(PRIORITY_LABELS_TR["seasonal"], "seasonal")
        self.priority_combo.addItem(PRIORITY_LABELS_TR["hidden"], "hidden")
        self.priority_combo.currentIndexChanged.connect(self._schedule_autosave)
        priority_line.addWidget(self.priority_combo, 1)
        self.btn_save = QPushButton("Kaydet")
        self.btn_save.clicked.connect(self._save_current)
        priority_line.addWidget(self.btn_save)
        decision_layout.addLayout(priority_line)

        self.auto_next = QCheckBox("Isaretleyince sonraki kayda gec")
        self.auto_next.setChecked(True)
        decision_layout.addWidget(self.auto_next)

        decision_layout.addWidget(QLabel("Inceleme notu"))
        self.note_edit = QTextEdit()
        self.note_edit.setPlaceholderText("Opsiyonel not")
        self.note_edit.setFixedHeight(120)
        self.note_edit.textChanged.connect(self._schedule_autosave)
        decision_layout.addWidget(self.note_edit)

        self.current_decision_label = QLabel("-")
        decision_layout.addWidget(self.current_decision_label)

        right_layout.addWidget(decision_box)
        right_layout.addStretch(1)

        splitter.addWidget(left_panel)
        splitter.addWidget(right_panel)
        splitter.setStretchFactor(0, 5)
        splitter.setStretchFactor(1, 2)
        root_layout.addWidget(splitter, 1)

    @staticmethod
    def _configure_flow_text(widget: QTextEdit, extra_pt: int = 0) -> None:
        font = widget.font()
        if font.pointSize() > 0:
            base = max(font.pointSize(), 12)
            font.setPointSize(base + max(0, int(extra_pt)))
            widget.setFont(font)
        widget.setLineWrapMode(QTextEdit.LineWrapMode.WidgetWidth)
        widget.setWordWrapMode(QTextOption.WrapMode.WrapAtWordBoundaryOrAnywhere)
        widget.setHorizontalScrollBarPolicy(Qt.ScrollBarPolicy.ScrollBarAlwaysOff)

    def refresh(self) -> None:
        self._suspend_autosave = True
        payload = self.store.current_payload()
        summary = payload["summary"]
        rec = payload["record"]
        cursor = payload["cursor"]
        total = payload["total"]
        decision = payload["decision"]

        self.summary_label.setText(
            f"Kayit {cursor + 1}/{total} | approved: {summary['approved']} | backlog: {summary['backlog']} | pending: {summary['pending']}"
        )
        index = self.dataset_filter_combo.findData(payload.get("dataset_filter", "all"))
        if index >= 0:
            self.dataset_filter_combo.setCurrentIndex(index)
        view = _extract_record_view(rec)
        self.record_title.setText(view["id"])
        self.record_meta.setText(f"Dataset: {rec.get('_dataset', '-')}")
        self.info_type.setText(view["record_type"])
        self.info_id.setText(view["id"])
        self.info_technical.setText(view["technical"])
        self.info_source.setText(view["source"])
        self.tr_text.setPlainText(view["tr_text"])
        self.ar_text.setPlainText(view["ar_text"])
        self.en_text.setPlainText(view["en_text"])
        self.book_ref_edit.setText(str(rec.get("book_reference_tr", "")))
        self.book_ref_edit.setVisible(str(rec.get("_dataset", "")) == "hadith")
        self.tr_ref_preview.setVisible(str(rec.get("_dataset", "")) == "hadith")
        self.en_warning.setText(_english_caps_warning(view["en_text"]))

        self._update_tr_ref_preview()

        self.note_edit.setPlainText(decision.get("note", "") or "")
        status = decision.get("status", "pending")
        self._selected_status = status if status in VALID_STATUSES else "pending"
        priority_key = _normalize_priority(decision.get("priority", "normal"))
        index = self.priority_combo.findData(priority_key)
        self.priority_combo.setCurrentIndex(index if index >= 0 else 0)
        updated_at = decision.get("updated_at", "-")
        self.current_decision_label.setText(
            f"Mevcut durum: {self._selected_status} | oncelik: {priority_key} | guncelleme: {updated_at}"
        )
        self._suspend_autosave = False

    def _on_dataset_filter_changed(self) -> None:
        if self._suspend_autosave:
            return
        self._save_current(show_message=False)
        new_filter = str(self.dataset_filter_combo.currentData() or "all")
        self.store.set_dataset_filter(new_filter)
        self.refresh()

    def _on_tr_text_changed(self) -> None:
        self._update_tr_ref_preview()
        self._schedule_autosave()

    def _on_book_ref_changed(self) -> None:
        self._update_tr_ref_preview()
        self._schedule_autosave()

    def _update_tr_ref_preview(self) -> None:
        payload = self.store.current_payload()
        rec = payload.get("record", {})
        if str(rec.get("_dataset", "")) != "hadith":
            self.tr_ref_preview.setText("")
            return
        original_tr = self.tr_text.toPlainText()
        existing_ref = self.book_ref_edit.text().strip()
        tails = ReviewStore._detect_trailing_book_ref_tails(original_tr)
        cleaned_tr, merged_ref = ReviewStore._extract_trailing_book_ref(original_tr, existing_ref)
        if not tails and cleaned_tr == original_tr and (merged_ref or "") == (existing_ref or ""):
            self.tr_ref_preview.setText("Dipnot: (TR sonunda tasinacak parantez bulunamadi)")
            return

        text = ""
        if tails:
            text += f"TR sonundan tasinacak: {'; '.join(tails)}\n"
        if merged_ref:
            text += f"book_reference_tr (hedef): {merged_ref}"
        self.tr_ref_preview.setText(text.strip())

    def _schedule_autosave(self) -> None:
        if self._suspend_autosave:
            return
        self._autosave_timer.start()

    def _autosave_now(self) -> None:
        if self._suspend_autosave:
            return
        note = self.note_edit.toPlainText().strip()
        priority = str(self.priority_combo.currentData() or "normal")
        payload = self.store.save_current(
            status=self._selected_status if self._selected_status in VALID_STATUSES else "pending",
            text_tr=self.tr_text.toPlainText(),
            text_ar=self.ar_text.toPlainText(),
            text_en=self.en_text.toPlainText(),
            book_reference_tr=self.book_ref_edit.text().strip(),
            note=note,
            priority=priority,
            move_next=False,
        )
        decision = payload.get("decision", {})
        updated_at = decision.get("updated_at", "-")
        self.current_decision_label.setText(
            f"Mevcut durum: {self._selected_status} | oncelik: {priority} | guncelleme: {updated_at}"
        )

    def _navigate(self, direction: str) -> None:
        self._save_current(show_message=False)
        self.store.move_cursor(direction)
        self.refresh()

    def _next_pending(self) -> None:
        self._save_current(show_message=False)
        moved = self.store.move_to_next_status("pending")
        if moved is None:
            QMessageBox.information(
                self,
                "Bilgi",
                "Bu konumdan sonra pending kayit bulunamadi.",
            )
        self.refresh()

    def _jump_to_id(self) -> None:
        self._save_current(show_message=False)
        target = self.jump_id.text().strip()
        dataset = str(self.jump_dataset.currentData() or "all")
        moved = self.store.jump_to_record(target, dataset=dataset)
        if moved is None:
            QMessageBox.warning(
                self,
                "Kayit bulunamadi",
                "Girdiginiz ID icin kayit bulunamadi. ID ve filtreyi kontrol edin.",
            )
            return
        self.refresh()

    def _set_status(self, status: str) -> None:
        self._selected_status = status
        self._save_current(move_next=self.auto_next.isChecked(), show_message=False)

    def _save_current(
        self, move_next: bool = False, show_message: bool = False
    ) -> None:
        if self._autosave_timer.isActive():
            self._autosave_timer.stop()
        note = self.note_edit.toPlainText().strip()
        priority = str(self.priority_combo.currentData() or "normal")
        self.store.save_current(
            status=self._selected_status,
            text_tr=self.tr_text.toPlainText(),
            text_ar=self.ar_text.toPlainText(),
            text_en=self.en_text.toPlainText(),
            book_reference_tr=self.book_ref_edit.text().strip(),
            note=note,
            priority=priority,
            move_next=move_next,
        )
        self.refresh()
        if show_message:
            QMessageBox.information(self, "Kaydedildi", "Kayit guncellendi.")

    def _export(self) -> None:
        self._save_current(show_message=False)
        out = self.store.export()
        self.refresh()
        QMessageBox.information(
            self,
            "Export tamam",
            "Ciktilar yazildi:\n"
            f"{out['directory']}\n\n"
            f"approved: {out['approved']}\n"
            f"rejected: {out['rejected']}\n"
            f"pending: {out['pending']}",
        )


def parse_args() -> argparse.Namespace:
    root = Path(__file__).resolve().parent
    repo_root = root.parent.parent
    parser = argparse.ArgumentParser(description="Local daily ayah/hadith review desktop tool.")
    parser.add_argument(
        "--dataset",
        default="all",
        choices=["all", "ayah", "hadith"],
        help="Which group to review: all | ayah | hadith",
    )
    parser.add_argument(
        "--ayah",
        default=str(repo_root / "Besmele" / "data" / "daily_panel" / "publish" / "ayetler.json"),
        help="Path to ayah JSON file.",
    )
    parser.add_argument(
        "--hadith",
        default=str(repo_root / "Besmele" / "data" / "daily_panel" / "publish" / "hadisler.json"),
        help="Path to hadith JSON file.",
    )
    parser.add_argument(
        "--state",
        default=str(root / "review_state.json"),
        help="Path to review state JSON file.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    root = Path(__file__).resolve().parent
    ayah_path = Path(args.ayah).resolve()
    hadith_path = Path(args.hadith).resolve()
    state_path = Path(args.state).resolve()

    if not ayah_path.exists():
        raise FileNotFoundError(f"Ayah input file not found: {ayah_path}")
    if not hadith_path.exists():
        raise FileNotFoundError(f"Hadith input file not found: {hadith_path}")

    store = ReviewStore(
        root=root,
        inputs=InputConfig(ayah_path=ayah_path, hadith_path=hadith_path),
        state_path=state_path,
        dataset_filter=str(getattr(args, "dataset", "all") or "all"),
    )

    app = QApplication(sys.argv)
    window = ReviewWindow(store)
    window.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
