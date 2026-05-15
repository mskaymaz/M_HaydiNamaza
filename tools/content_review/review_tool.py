#!/usr/bin/env python3
"""Local-only desktop review tool for ayah/hadith draft content (PySide6)."""

from __future__ import annotations

import argparse
import json
import os
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

try:
    from PySide6.QtCore import Qt
    from PySide6.QtGui import QFont, QTextOption
    from PySide6.QtWidgets import (
        QApplication,
        QCheckBox,
        QComboBox,
        QFormLayout,
        QGridLayout,
        QGroupBox,
        QHBoxLayout,
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


VALID_STATUSES = {"approved", "rejected", "pending"}
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
    def __init__(self, root: Path, inputs: InputConfig, state_path: Path) -> None:
        self.root = root
        self.inputs = inputs
        self.state_path = state_path
        self.output_dir = root / "output"
        self.output_dir.mkdir(parents=True, exist_ok=True)

        ayah_records = self._read_json_array(inputs.ayah_path)
        hadith_records = self._read_json_array(inputs.hadith_path)

        self.records: list[dict[str, Any]] = []
        for rec in ayah_records:
            self.records.append(self._normalize_record(rec, "ayah"))
        for rec in hadith_records:
            self.records.append(self._normalize_record(rec, "hadith"))

        if not self.records:
            raise RuntimeError("No records found in input files.")

        self.state = self._load_or_init_state()
        self._save_state()

    @staticmethod
    def _read_json_array(path: Path) -> list[dict[str, Any]]:
        # utf-8-sig handles both BOM and non-BOM UTF-8 safely.
        with path.open("r", encoding="utf-8-sig") as f:
            data = json.load(f)
        if not isinstance(data, list):
            raise ValueError(f"Expected JSON array in {path}")
        return data

    @staticmethod
    def _normalize_record(record: dict[str, Any], dataset: str) -> dict[str, Any]:
        if "id" not in record:
            raise ValueError(f"Record missing id in dataset={dataset}")
        out = dict(record)
        out["_dataset"] = dataset
        out["_record_key"] = f"{dataset}:{record['id']}"
        return out

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
        state.setdefault("input_files", {})
        state.setdefault("decisions", {})
        state["cursor"] = max(0, min(int(state["cursor"]), len(self.records) - 1))
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
        totals = {"approved": 0, "rejected": 0, "pending": 0}
        decisions = self.state.get("decisions", {})
        for rec in self.records:
            key = rec["_record_key"]
            status = decisions.get(key, {}).get("status", "pending")
            if status not in VALID_STATUSES:
                status = "pending"
            totals[status] += 1
        return totals

    def current_payload(self) -> dict[str, Any]:
        cursor = int(self.state["cursor"])
        rec = self.records[cursor]
        decisions = self.state.get("decisions", {})
        raw_decision = decisions.get(rec["_record_key"], {})
        current_decision = {
            "status": raw_decision.get("status", "pending"),
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
        }

    def move_cursor(self, direction: str) -> dict[str, Any]:
        cursor = int(self.state["cursor"])
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
        self._save_state()
        return self.current_payload()

    def save_current(
        self,
        status: str,
        note: str = "",
        priority: str = "normal",
        move_next: bool = False,
    ) -> dict[str, Any]:
        if status not in VALID_STATUSES:
            raise ValueError("Invalid status.")
        if priority not in VALID_PRIORITIES:
            raise ValueError("Invalid priority.")
        cursor = int(self.state["cursor"])
        rec = self.records[cursor]
        key = rec["_record_key"]
        previous = self.state["decisions"].get(key, {})
        self.state["decisions"][key] = {
            "status": status,
            "note": note,
            "priority": priority,
            "boost_start_date": str(previous.get("boost_start_date", "") or ""),
            "boost_end_date": str(previous.get("boost_end_date", "") or ""),
            "updated_at": self._utc_now(),
        }
        if move_next:
            self.state["cursor"] = min(cursor + 1, len(self.records) - 1)
        self._save_state()
        return self.current_payload()

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
            "rejected": [],
            "pending": [],
        }

        for rec in self.records:
            key = rec["_record_key"]
            decision = decisions.get(key, {})
            status = decision.get("status", "pending")
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
        self._atomic_json_write(rejected_path, buckets["rejected"])
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
        view["tr_text"] = str(translation.get("tr", "-"))
        view["ar_text"] = str(text_obj.get("ar", "-"))
        view["en_text"] = str(translation.get("en", "-"))
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
        self.position_label = QLabel("-")
        top_layout.addWidget(self.summary_label, 0, 0, 1, 3)
        top_layout.addWidget(self.position_label, 1, 0, 1, 3)

        self.btn_first = QPushButton("Ilk")
        self.btn_prev = QPushButton("Onceki")
        self.btn_next = QPushButton("Sonraki")
        self.btn_last = QPushButton("Son")
        self.btn_export = QPushButton("Cikti Uret")
        self.btn_first.clicked.connect(lambda: self._navigate("first"))
        self.btn_prev.clicked.connect(lambda: self._navigate("prev"))
        self.btn_next.clicked.connect(lambda: self._navigate("next"))
        self.btn_last.clicked.connect(lambda: self._navigate("last"))
        self.btn_export.clicked.connect(self._export)
        top_layout.addWidget(self.btn_first, 2, 0)
        top_layout.addWidget(self.btn_prev, 2, 1)
        top_layout.addWidget(self.btn_next, 2, 2)
        top_layout.addWidget(self.btn_last, 3, 0)
        top_layout.addWidget(self.btn_export, 3, 1, 1, 2)
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
        info_form = QFormLayout(info_box)
        self.info_type = QLabel("-")
        self.info_id = QLabel("-")
        self.info_technical = QLabel("-")
        self.info_source = QLabel("-")
        self.info_technical.setWordWrap(True)
        self.info_source.setWordWrap(True)
        info_form.addRow("Tur:", self.info_type)
        info_form.addRow("Kayit ID:", self.info_id)
        info_form.addRow("Bilgi:", self.info_technical)
        info_form.addRow("Kaynak Notu:", self.info_source)
        left_layout.addWidget(info_box)

        lang_splitter = QSplitter(Qt.Orientation.Vertical)
        tr_box = QGroupBox("Turkce Metin")
        tr_layout = QVBoxLayout(tr_box)
        self.tr_text = QTextEdit()
        self.tr_text.setReadOnly(True)
        self._configure_flow_text(self.tr_text)
        tr_layout.addWidget(self.tr_text)

        ar_box = QGroupBox("Arapca Metin")
        ar_layout = QVBoxLayout(ar_box)
        self.ar_text = QTextEdit()
        self.ar_text.setReadOnly(True)
        self._configure_flow_text(self.ar_text)
        ar_layout.addWidget(self.ar_text)

        en_box = QGroupBox("Ingilizce Metin")
        en_layout = QVBoxLayout(en_box)
        self.en_text = QTextEdit()
        self.en_text.setReadOnly(True)
        self._configure_flow_text(self.en_text)
        self.en_warning = QLabel("")
        self.en_warning.setStyleSheet("color:#b23b3b;")
        self.en_warning.setWordWrap(True)
        en_layout.addWidget(self.en_text)
        en_layout.addWidget(self.en_warning)

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
        self.btn_approved = QPushButton("Onayla")
        self.btn_rejected = QPushButton("Reddet")
        self.btn_pending = QPushButton("Beklet")
        self.btn_approved.setStyleSheet("background:#eaf8ef;border:1px solid #6dbd7f;")
        self.btn_rejected.setStyleSheet("background:#fff1f1;border:1px solid #e59a9a;")
        self.btn_pending.setStyleSheet("background:#fff9ee;border:1px solid #d4b16a;")
        self.btn_approved.clicked.connect(lambda: self._set_status("approved"))
        self.btn_rejected.clicked.connect(lambda: self._set_status("rejected"))
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
        decision_layout.addWidget(self.note_edit)

        self.current_decision_label = QLabel("-")
        decision_layout.addWidget(self.current_decision_label)

        right_layout.addWidget(decision_box)
        right_layout.addStretch(1)

        splitter.addWidget(left_panel)
        splitter.addWidget(right_panel)
        splitter.setStretchFactor(0, 3)
        splitter.setStretchFactor(1, 2)
        root_layout.addWidget(splitter, 1)

    @staticmethod
    def _configure_flow_text(widget: QTextEdit) -> None:
        widget.setLineWrapMode(QTextEdit.LineWrapMode.WidgetWidth)
        widget.setWordWrapMode(QTextOption.WrapMode.WrapAtWordBoundaryOrAnywhere)
        widget.setHorizontalScrollBarPolicy(Qt.ScrollBarPolicy.ScrollBarAlwaysOff)

    def refresh(self) -> None:
        payload = self.store.current_payload()
        summary = payload["summary"]
        rec = payload["record"]
        cursor = payload["cursor"]
        total = payload["total"]
        decision = payload["decision"]

        self.summary_label.setText(
            "Toplam: "
            f"{total} | approved: {summary['approved']} | rejected: {summary['rejected']} | pending: {summary['pending']}"
        )
        self.position_label.setText(f"Kayit {cursor + 1}/{total}")
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
        self.en_warning.setText(_english_caps_warning(view["en_text"]))

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

    def _navigate(self, direction: str) -> None:
        self._save_current(show_message=False)
        self.store.move_cursor(direction)
        self.refresh()

    def _set_status(self, status: str) -> None:
        self._selected_status = status
        self._save_current(move_next=self.auto_next.isChecked(), show_message=False)

    def _save_current(
        self, move_next: bool = False, show_message: bool = False
    ) -> None:
        note = self.note_edit.toPlainText().strip()
        priority = str(self.priority_combo.currentData() or "normal")
        self.store.save_current(
            status=self._selected_status,
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
        "--ayah",
        default=str(repo_root / "Besmele" / "data" / "daily_panel" / "ayahs_draft.json"),
        help="Path to ayah draft JSON file.",
    )
    parser.add_argument(
        "--hadith",
        default=str(repo_root / "Besmele" / "data" / "daily_panel" / "hadiths_draft.json"),
        help="Path to hadith draft JSON file.",
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
    )

    app = QApplication(sys.argv)
    window = ReviewWindow(store)
    window.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
