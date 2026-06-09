#!/usr/bin/env python3
"""Approved-only mobile preview and priority editor."""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime
from pathlib import Path
from typing import Any

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

try:
    from PySide6.QtCore import Qt
    from PySide6.QtGui import QFont, QFontDatabase
    from PySide6.QtWidgets import (
        QApplication,
        QComboBox,
        QFrame,
        QHBoxLayout,
        QLabel,
        QLineEdit,
        QMainWindow,
        QMessageBox,
        QPushButton,
        QSizePolicy,
        QVBoxLayout,
        QWidget,
    )
except ImportError:
    print("PySide6 not found.")
    print("Install command: py -m pip install PySide6")
    raise SystemExit(1)

from core.approved_preview import ApprovedContentNavigator, MobilePreviewItem
from core.backup import BackupManager
from core.logger import ActionLogger
from core.models import AppPaths
from core.storage import ContentRepository
from ui.mobile_preview import MobilePreviewCard
from ui.scale import pt, scale


PRIORITY_LABELS = {
    1: "Normal",
    2: "Sık",
    3: "Daha sık",
}


class OnayStateStore:
    def __init__(self, path: Path) -> None:
        self._path = path

    def mark(self, kind: str, row: dict[str, Any], action: str) -> None:
        payload = self._read()
        processed = payload.setdefault("processed", {})
        kind_map = processed.setdefault(kind, {})
        at = datetime.now().replace(microsecond=0).isoformat()
        entry = {
            "action": action,
            "at": at,
            "id": str(row.get("id") or "").strip(),
            "ref": str(row.get("ref") or "").strip(),
        }
        for key in self._keys(kind, row):
            kind_map[key] = entry
        self._write(payload)

    @staticmethod
    def _keys(kind: str, row: dict[str, Any]) -> list[str]:
        keys = [
            str(row.get("id") or "").strip(),
            str(row.get("ref") or "").strip(),
        ]
        if kind == "hadith":
            number = str(row.get("hadith_number") or "").strip()
            if number:
                keys.extend([number, f"riyazussalihin/{number}"])
        return [key for index, key in enumerate(keys) if key and key not in keys[:index]]

    def _read(self) -> dict[str, Any]:
        if not self._path.exists():
            return {"schema_version": "1.0.0", "processed": {"ayah": {}, "hadith": {}, "esma": {}}}
        with self._path.open("r", encoding="utf-8-sig") as handle:
            payload = json.load(handle)
        if not isinstance(payload, dict):
            return {"schema_version": "1.0.0", "processed": {"ayah": {}, "hadith": {}, "esma": {}}}
        payload.setdefault("schema_version", "1.0.0")
        payload.setdefault("processed", {"ayah": {}, "hadith": {}, "esma": {}})
        return payload

    def _write(self, payload: dict[str, Any]) -> None:
        self._path.parent.mkdir(parents=True, exist_ok=True)
        tmp = self._path.with_suffix(self._path.suffix + ".tmp")
        with tmp.open("w", encoding="utf-8", newline="\n") as handle:
            json.dump(payload, handle, ensure_ascii=False, indent=2)
            handle.write("\n")
        tmp.replace(self._path)


def _default_paths(repo_root: Path, tool_root: Path) -> AppPaths:
    archive_root = repo_root / "assets" / "data" / "daily_content" / "archive"
    approved_root = repo_root / "assets" / "data" / "daily_content" / "approved"
    return AppPaths(
        repo_root=repo_root,
        tool_root=tool_root,
        archive_ayah_path=archive_root / "ayahs.pending_review.v1.json",
        archive_hadith_path=archive_root / "hadiths.pending_review.v1.json",
        archive_esma_path=archive_root / "esmaul_husna.pending_review.v1.json",
        approved_ayah_path=approved_root / "ayahs.v1.approved.json",
        approved_hadith_path=approved_root / "hadiths.v1.approved.json",
        approved_esma_path=approved_root / "esmaul_husna.v1.approved.json",
        state_path=tool_root / "review_state.json",
        log_path=tool_root / "tool.log",
        backup_dir=tool_root / "backups",
    )


def _load_preview_fonts(repo_root: Path) -> None:
    font_root = repo_root / "assets" / "fonts" / "google"
    for name in (
        "ReemKufiFun-wght.ttf",
        "Mirza-Regular.ttf",
        "Lateef-Regular.ttf",
        "NotoNaskhArabic-wght.ttf",
        "Amiri-Regular.ttf",
    ):
        path = font_root / name
        if path.exists():
            QFontDatabase.addApplicationFont(str(path))


class ApprovedJsonEditor:
    def __init__(
        self,
        paths: AppPaths,
        logger: ActionLogger,
        backup_manager: BackupManager,
        onay_state: OnayStateStore,
    ) -> None:
        self._paths = paths
        self._logger = logger
        self._backup_manager = backup_manager
        self._onay_state = onay_state

    def priority(self, kind: str, record_id: str) -> int:
        payload = self._read_payload(kind)
        for row in payload["records"]:
            if self._row_id(row) == record_id:
                return self._safe_priority(row.get("priority"))
        return 1

    def durum(self, kind: str, record_id: str) -> str:
        payload = self._read_payload(kind)
        for row in payload["records"]:
            if self._row_id(row) == record_id:
                return str(row.get("durum") or row.get("status") or "onayli").strip()
        return "onayli"

    def approve_review(self, kind: str, record_id: str, priority: int) -> bool:
        payload = self._read_payload(kind)
        changed = False
        for row in payload["records"]:
            if self._row_id(row) == record_id:
                if self._safe_priority(row.get("priority")) != priority:
                    row["priority"] = priority
                    changed = True
                if kind in {"ayah", "hadith"} and row.get("durum") != "yayina_hazir":
                    row["durum"] = "yayina_hazir"
                    changed = True
                now = datetime.now().replace(microsecond=0).isoformat()
                row["onay_review"] = {
                    "action": "approved",
                    "processed_at": now,
                    "tool": "onay.py",
                }
                row["onay_reviewed_at"] = now
                self._onay_state.mark(kind, row, "approved")
                changed = True
                break
        if not changed:
            return False
        self._write_payload(kind, payload)
        self._logger.log("approved_review_update", kind=kind, record_id=record_id, priority=priority)
        return True

    def delete(self, kind: str, record_id: str) -> bool:
        payload = self._read_payload(kind)
        rows = payload["records"]
        kept = [row for row in rows if self._row_id(row) != record_id]
        if len(kept) == len(rows):
            return False
        for row in rows:
            if self._row_id(row) == record_id:
                self._onay_state.mark(kind, row, "deleted")
                break
        payload["records"] = kept
        payload["root"][payload["root_key"]] = kept
        self._write_payload(kind, payload)
        self._logger.log("approved_delete", kind=kind, record_id=record_id)
        return True

    def _read_payload(self, kind: str) -> dict[str, Any]:
        path = self._approved_path(kind)
        with path.open("r", encoding="utf-8-sig") as handle:
            root = json.load(handle)
        if isinstance(root, dict) and isinstance(root.get("records"), list):
            return {"path": path, "root": root, "records": root["records"], "root_key": "records"}
        raise ValueError(f"Approved JSON yapisi okunamadi: {path}")

    def _write_payload(self, kind: str, payload: dict[str, Any]) -> None:
        path = payload["path"]
        self._backup_manager.create_backup(path)
        payload["root"]["content_version"] = f"onay-tool-{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        tmp = path.with_suffix(path.suffix + ".tmp")
        with tmp.open("w", encoding="utf-8", newline="\n") as handle:
            json.dump(payload["root"], handle, ensure_ascii=False, indent=2)
            handle.write("\n")
        tmp.replace(path)

    def _approved_path(self, kind: str) -> Path:
        mapping = {
            "ayah": self._paths.approved_ayah_path,
            "hadith": self._paths.approved_hadith_path,
            "esma": self._paths.approved_esma_path,
        }
        return mapping[kind]

    @staticmethod
    def _row_id(row: object) -> str:
        if not isinstance(row, dict):
            return ""
        return str(row.get("id") or "").strip()

    @staticmethod
    def _safe_priority(value: object) -> int:
        try:
            priority = int(value)
        except (TypeError, ValueError):
            return 1
        return priority if priority in PRIORITY_LABELS else 1


class ApprovalWindow(QMainWindow):
    def __init__(self, repository: ContentRepository, editor: ApprovedJsonEditor) -> None:
        super().__init__()
        self._repository = repository
        self._editor = editor
        self._navigator = ApprovedContentNavigator(repository)
        self._show_turkish = True
        self._show_english = False
        self._show_arabic = False
        self._type_buttons: dict[str, QPushButton] = {}
        self._language_buttons: dict[str, QPushButton] = {}
        self.setWindowTitle("Onaylı İçerik / Mobil Önizleme")
        self.resize(scale(980), scale(1020))
        self._build_ui()
        self.refresh()

    def refresh(self) -> None:
        current_type = self._navigator.current_type
        self._navigator.reload()
        self._navigator.set_content_type(current_type)
        self._sync_controls()
        self._sync_view()

    def _build_ui(self) -> None:
        root_widget = QWidget()
        root = QVBoxLayout(root_widget)
        root.setContentsMargins(scale(18), scale(18), scale(18), scale(18))
        root.setSpacing(scale(10))

        title = QLabel("Onaylı İçerik")
        title.setStyleSheet(f"font-size: {pt(18)}pt; font-weight: 700;")
        root.addWidget(title)

        selector_row = QHBoxLayout()
        selector_row.setSpacing(scale(8))
        self._type_buttons["ayah"] = self._build_selector_button("Ayet")
        self._type_buttons["hadith"] = self._build_selector_button("Hadis")
        self._type_buttons["esma"] = self._build_selector_button("Esma")
        self._type_buttons["ayah"].clicked.connect(lambda: self._select_type("ayah"))
        self._type_buttons["hadith"].clicked.connect(lambda: self._select_type("hadith"))
        self._type_buttons["esma"].clicked.connect(lambda: self._select_type("esma"))
        for button in self._type_buttons.values():
            selector_row.addWidget(button)
        root.addLayout(selector_row)

        control_row = QHBoxLayout()
        control_row.setSpacing(scale(8))
        self.kind_badge = QLabel("-")
        self.kind_badge.setAlignment(Qt.AlignCenter)
        self.kind_badge.setFixedHeight(scale(34))
        self.kind_badge.setMinimumWidth(scale(110))
        self.kind_badge.setStyleSheet(
            f"background:#1F7A3E;color:white;border-radius:{scale(17)}px;"
            f"font-size:{pt(13)}pt;font-weight:700;padding:0 {scale(12)}px;"
        )
        self.position_label = QLabel("0 / 0")
        self.position_label.setStyleSheet(f"font-size:{pt(13)}pt;font-weight:600;")
        self.start_edit = QLineEdit()
        self.start_edit.returnPressed.connect(self._jump_to_value)
        self.start_btn = QPushButton("Git")
        self.start_btn.clicked.connect(self._jump_to_value)
        self.prev_btn = QPushButton("Geri")
        self.prev_btn.clicked.connect(self._show_previous)
        self.next_btn = QPushButton("İleri")
        self.next_btn.clicked.connect(self._show_next)
        self.reload_btn = QPushButton("Yenile")
        self.reload_btn.clicked.connect(self.refresh)
        control_row.addWidget(self.kind_badge)
        control_row.addWidget(self.position_label)
        control_row.addWidget(self.start_edit, 1)
        control_row.addWidget(self.start_btn)
        control_row.addWidget(self.prev_btn)
        control_row.addWidget(self.next_btn)
        control_row.addWidget(self.reload_btn)
        root.addLayout(control_row)

        phone_shell = QFrame()
        phone_shell.setFixedSize(scale(620), scale(780))
        phone_shell.setStyleSheet(
            f"background:#171717;border:{scale(2)}px solid #2F2F2F;border-radius:{scale(34)}px;"
        )
        phone_layout = QVBoxLayout(phone_shell)
        phone_layout.setContentsMargins(scale(12), scale(14), scale(12), scale(14))

        screen = QFrame()
        screen.setStyleSheet(f"background:#F3EFE2;border-radius:{scale(26)}px;")
        screen_layout = QVBoxLayout(screen)
        screen_layout.setContentsMargins(scale(14), scale(20), scale(14), scale(18))
        screen_layout.setSpacing(scale(10))

        preview_panel = QFrame()
        preview_panel.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Expanding)
        preview_panel.setStyleSheet(
            f"background:#93BFA2;border:{scale(1)}px solid rgba(31,122,62,0.35);border-radius:{scale(14)}px;"
        )
        preview_layout = QVBoxLayout(preview_panel)
        preview_layout.setContentsMargins(scale(12), scale(10), scale(12), scale(10))
        preview_layout.setSpacing(scale(10))

        top_row = QHBoxLayout()
        self.heading_label = QLabel("-")
        self.heading_label.setAlignment(Qt.AlignCenter)
        self.heading_label.setStyleSheet(f"font-size:{pt(23)}pt;font-weight:700;color:#111111;")
        top_row.addWidget(self.heading_label, 1)
        self._language_buttons["tr"] = self._build_toggle_chip("TR")
        self._language_buttons["en"] = self._build_toggle_chip("EN")
        self._language_buttons["ar"] = self._build_toggle_chip("عربي", font_size=pt(10))
        self._language_buttons["tr"].clicked.connect(lambda: self._toggle_language("tr"))
        self._language_buttons["en"].clicked.connect(lambda: self._toggle_language("en"))
        self._language_buttons["ar"].clicked.connect(lambda: self._toggle_language("ar"))
        top_row.addWidget(self._language_buttons["tr"])
        top_row.addWidget(self._language_buttons["en"])
        top_row.addWidget(self._language_buttons["ar"])
        preview_layout.addLayout(top_row)

        self.card = MobilePreviewCard(font_boost=6)
        preview_layout.addWidget(self.card, 1)
        screen_layout.addWidget(preview_panel, 1)
        phone_layout.addWidget(screen)
        root.addWidget(phone_shell, 0, Qt.AlignHCenter)

        edit_row = QHBoxLayout()
        edit_row.setSpacing(scale(8))
        self.priority_combo = QComboBox()
        for value, label in PRIORITY_LABELS.items():
            self.priority_combo.addItem(f"{value} - {label}", value)
        self.approved_label = QLabel("Onaylı")
        self.approved_label.setStyleSheet(f"font-size:{pt(12)}pt;font-weight:700;color:#1F7A3E;")
        self.save_priority_btn = QPushButton("Onayla / Kaydet")
        self.save_priority_btn.clicked.connect(self._approve_current)
        self.delete_btn = QPushButton("Sil")
        self.delete_btn.clicked.connect(self._delete_current)
        self.delete_btn.setStyleSheet("background:#8A1F1F;color:white;font-weight:700;")
        edit_row.addWidget(QLabel("Priority"))
        edit_row.addWidget(self.priority_combo)
        edit_row.addWidget(self.approved_label)
        edit_row.addStretch(1)
        edit_row.addWidget(self.save_priority_btn)
        edit_row.addWidget(self.delete_btn)
        root.addLayout(edit_row)

        self.meta_label = QLabel("-")
        self.meta_label.setWordWrap(True)
        self.meta_label.setAlignment(Qt.AlignCenter)
        self.meta_label.setStyleSheet(f"font-size:{pt(11)}pt;color:#5A5A5A;")
        root.addWidget(self.meta_label)

        self.setCentralWidget(root_widget)

    def _select_type(self, kind: str) -> None:
        self._navigator.set_content_type(kind, reset_index=True)
        self._sync_controls()
        self._sync_view()

    def _jump_to_value(self) -> None:
        item = self._navigator.jump_to(self.start_edit.text())
        if item is None and self._navigator.count() > 0:
            self.meta_label.setText("Girilen numara veya referans bulunamadı.")
            return
        self._sync_view()

    def _toggle_language(self, code: str) -> None:
        active_count = sum((self._show_turkish, self._show_english, self._show_arabic))
        if code == "tr":
            if self._show_turkish and active_count == 1:
                return
            self._show_turkish = not self._show_turkish
        elif code == "en":
            if self._show_english and active_count == 1:
                return
            self._show_english = not self._show_english
        else:
            if self._show_arabic and active_count == 1:
                return
            self._show_arabic = not self._show_arabic
        self._sync_language_buttons()
        self._sync_view()

    def _approve_current(self) -> None:
        item = self._navigator.current_item()
        if item is None:
            return
        priority = int(self.priority_combo.currentData() or 1)
        changed = self._editor.approve_review(item.kind, item.record_id, priority)
        self.refresh()
        self.meta_label.setText(
            f"{item.record_id} onay/durum kaydedildi." if changed else f"{item.record_id} zaten güncel."
        )

    def _delete_current(self) -> None:
        item = self._navigator.current_item()
        if item is None:
            return
        reply = QMessageBox.question(
            self,
            "Approved kaydı sil",
            f"{item.kind_label} kaydı approved JSON'dan silinecek:\n{item.record_id}\n\nArşiv dosyalarına dokunulmayacak. Devam edilsin mi?",
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No,
            QMessageBox.StandardButton.No,
        )
        if reply != QMessageBox.StandardButton.Yes:
            return
        deleted = self._editor.delete(item.kind, item.record_id)
        self.refresh()
        self.meta_label.setText(
            f"{item.record_id} approved JSON'dan silindi." if deleted else f"{item.record_id} bulunamadı."
        )

    def _sync_controls(self) -> None:
        for kind, button in self._type_buttons.items():
            selected = kind == self._navigator.current_type
            button.setChecked(selected)
            button.setStyleSheet(self._selector_style(selected))
        self.start_edit.setPlaceholderText(self._navigator.start_hint())
        self._sync_language_buttons()

    def _sync_language_buttons(self) -> None:
        states = {"tr": self._show_turkish, "en": self._show_english, "ar": self._show_arabic}
        for code, button in self._language_buttons.items():
            selected = states[code]
            button.setChecked(selected)
            button.setStyleSheet(self._toggle_style(selected, font_size=pt(10) if code == "ar" else pt(11)))

    def _sync_view(self) -> None:
        item = self._navigator.current_item()
        self.card.set_item(
            item,
            show_arabic=self._show_arabic,
            show_turkish=self._show_turkish,
            show_english=self._show_english,
            empty_message=self._navigator.empty_message(),
        )
        self.position_label.setText(self._navigator.position_label())
        self.prev_btn.setEnabled(self._navigator.can_go_previous())
        self.next_btn.setEnabled(self._navigator.can_go_next())
        self.save_priority_btn.setEnabled(item is not None)
        self.delete_btn.setEnabled(item is not None)
        self.kind_badge.setText(item.kind_label if item is not None else self._kind_label())
        if item is None:
            self.heading_label.setText(self._kind_heading())
            self.meta_label.setText(self._navigator.empty_message())
            self.priority_combo.setCurrentIndex(0)
            return
        self.heading_label.setText(item.heading)
        durum = self._editor.durum(item.kind, item.record_id)
        self.meta_label.setText(f"{item.record_id} | {item.ref} | durum={durum}")
        priority = self._editor.priority(item.kind, item.record_id)
        self.priority_combo.setCurrentIndex(max(0, self.priority_combo.findData(priority)))

    def _show_previous(self) -> None:
        self._navigator.go_previous()
        self._sync_view()

    def _show_next(self) -> None:
        self._navigator.go_next()
        self._sync_view()

    def _kind_heading(self) -> str:
        if self._navigator.current_type == "hadith":
            return "Günün Hadisi"
        if self._navigator.current_type == "esma":
            return "Esma"
        return "Günün Ayeti"

    def _kind_label(self) -> str:
        if self._navigator.current_type == "hadith":
            return "Hadis"
        if self._navigator.current_type == "esma":
            return "Esma"
        return "Ayet"

    @staticmethod
    def _build_selector_button(label: str) -> QPushButton:
        button = QPushButton(label)
        button.setCheckable(True)
        button.setMinimumHeight(scale(36))
        return button

    @staticmethod
    def _build_toggle_chip(label: str, font_size: int | None = None) -> QPushButton:
        chip = QPushButton(label)
        resolved_font_size = font_size if font_size is not None else pt(11)
        chip.setCheckable(True)
        chip.setFixedSize(scale(36), scale(36))
        chip.setCursor(Qt.PointingHandCursor)
        chip.setFocusPolicy(Qt.NoFocus)
        chip.setSizePolicy(QSizePolicy.Fixed, QSizePolicy.Fixed)
        chip.setStyleSheet(ApprovalWindow._toggle_style(True, font_size=resolved_font_size))
        return chip

    @staticmethod
    def _toggle_style(selected: bool, *, font_size: int) -> str:
        if selected:
            return (
                "background:#121212;color:white;border:2px solid #121212;"
                f"border-radius:{scale(18)}px;font-weight:700;font-size:{font_size}pt;"
            )
        return (
            "background:white;color:#111111;border:1.5px solid #FFFFFF;"
            f"border-radius:{scale(18)}px;font-weight:700;font-size:{font_size}pt;"
        )

    @staticmethod
    def _selector_style(selected: bool) -> str:
        if selected:
            return (
                "background:#1F7A3E;color:white;border:1px solid #1F7A3E;"
                f"border-radius:{scale(10)}px;font-size:{pt(12)}pt;font-weight:700;"
                f"padding:{scale(6)}px {scale(12)}px;"
            )
        return (
            "background:#F1F1F1;color:#222222;border:1px solid #D0D0D0;"
            f"border-radius:{scale(10)}px;font-size:{pt(12)}pt;font-weight:600;"
            f"padding:{scale(6)}px {scale(12)}px;"
        )


def parse_args() -> argparse.Namespace:
    tool_root = SCRIPT_DIR
    repo_root = tool_root.parent.parent
    defaults = _default_paths(repo_root, tool_root)
    parser = argparse.ArgumentParser(description="Approved content mobile preview / priority tool.")
    parser.add_argument("--ayah", default=str(defaults.archive_ayah_path), help="Archive ayah JSON path.")
    parser.add_argument("--hadith", default=str(defaults.archive_hadith_path), help="Archive hadith JSON path.")
    parser.add_argument("--esma", default=str(defaults.archive_esma_path), help="Archive esma JSON path.")
    parser.add_argument("--approved-ayah", default=str(defaults.approved_ayah_path), help="Approved ayah JSON path.")
    parser.add_argument("--approved-hadith", default=str(defaults.approved_hadith_path), help="Approved hadith JSON path.")
    parser.add_argument("--approved-esma", default=str(defaults.approved_esma_path), help="Approved esma JSON path.")
    parser.add_argument("--state", default=str(defaults.state_path), help="Tool state JSON path.")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    tool_root = SCRIPT_DIR
    repo_root = tool_root.parent.parent
    paths = AppPaths(
        repo_root=repo_root,
        tool_root=tool_root,
        archive_ayah_path=Path(args.ayah).resolve(),
        archive_hadith_path=Path(args.hadith).resolve(),
        archive_esma_path=Path(args.esma).resolve(),
        approved_ayah_path=Path(args.approved_ayah).resolve(),
        approved_hadith_path=Path(args.approved_hadith).resolve(),
        approved_esma_path=Path(args.approved_esma).resolve(),
        state_path=Path(args.state).resolve(),
        log_path=tool_root / "tool.log",
        backup_dir=tool_root / "backups",
    )
    logger = ActionLogger(paths.log_path)
    backup_manager = BackupManager(paths.backup_dir)
    repository = ContentRepository(paths, logger, backup_manager)
    onay_state = OnayStateStore(tool_root / "onay_state.json")
    editor = ApprovedJsonEditor(paths, logger, backup_manager, onay_state)

    app = QApplication(sys.argv)
    _load_preview_fonts(repo_root)
    base_font = QFont(app.font())
    base_font.setPointSizeF(max(10.0, base_font.pointSizeF()))
    app.setFont(base_font)
    window = ApprovalWindow(repository, editor)
    window.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
