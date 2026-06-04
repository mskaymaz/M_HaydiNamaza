from __future__ import annotations

from dataclasses import replace
from datetime import datetime, timezone

from PySide6.QtWidgets import (
    QCheckBox,
    QComboBox,
    QFormLayout,
    QGridLayout,
    QGroupBox,
    QHBoxLayout,
    QLabel,
    QLineEdit,
    QMessageBox,
    QPushButton,
    QSpinBox,
    QTextEdit,
    QVBoxLayout,
    QWidget,
)

from core.models import AyahRecord, BaseRecord, EsmaRecord, HadithRecord, STATUS_VALUES
from core.storage import ContentRepository, StorageConflictError
from ui.mobile_preview import MobilePreviewWindow


STATUS_LABELS = {
    "draft": "Taslak",
    "fetched": "Veri alındı",
    "needs_review": "Inceleme gerekli",
    "needs_translation": "Ceviri gerekli",
    "needs_source_check": "Kaynak kontrolü gerekli",
    "approved": "Onaylandı",
    "rejected": "Reddedildi",
    "duplicate": "Mükerrer",
    "archived": "Arşive kaldırıldı",
}


class ReviewPanel(QWidget):
    def __init__(self, repository: ContentRepository) -> None:
        super().__init__()
        self.repository = repository
        self._preview_window: MobilePreviewWindow | None = None
        self._current_kind = "ayah"
        self._records: list[BaseRecord] = []
        self._current_record: BaseRecord | None = None
        self._build_ui()
        self.refresh()

    def _build_ui(self) -> None:
        layout = QVBoxLayout(self)
        layout.setSpacing(14)
        layout.setContentsMargins(10, 10, 10, 10)

        top_box = QGroupBox("Inceleme")
        top_layout = QGridLayout(top_box)
        top_layout.setHorizontalSpacing(10)
        top_layout.setVerticalSpacing(10)
        self.kind_combo = QComboBox()
        self.kind_combo.addItem("Ayet", "ayah")
        self.kind_combo.addItem("Hadis", "hadith")
        self.kind_combo.addItem("Esmaül Hüsna", "esma")
        self.kind_combo.currentIndexChanged.connect(self._on_kind_changed)
        self.summary_label = QLabel("-")
        self.nearby_hadith_check = self._build_status_check("Yakın hadis adayı")
        self.match_warning_label = QLabel("")
        self.match_warning_label.setWordWrap(True)
        self.match_warning_label.setStyleSheet("font-size: 14pt; font-weight: 700; color: #8a4b00;")
        self.jump_edit = QLineEdit()
        self.jump_edit.setPlaceholderText("Kimlik / referans")
        self.jump_btn = QPushButton("Git")
        self.jump_btn.clicked.connect(self._jump_to_record)
        self.prev_btn = QPushButton("Önceki")
        self.prev_btn.clicked.connect(lambda: self._move(-1))
        self.next_btn = QPushButton("Sonraki")
        self.next_btn.clicked.connect(lambda: self._move(1))
        self.reload_btn = QPushButton("Yenile")
        self.reload_btn.clicked.connect(self.refresh)
        self.undo_btn = QPushButton("Son Yazimi Geri Al")
        self.undo_btn.clicked.connect(self._undo_last)
        self.preview_btn = QPushButton("Mobil Önizleme / Mobile Preview")
        self.preview_btn.clicked.connect(self._open_mobile_preview)
        top_layout.addWidget(QLabel("Tur"), 0, 0)
        top_layout.addWidget(self.kind_combo, 0, 1)
        top_layout.addWidget(self.summary_label, 0, 2, 1, 3)
        top_layout.addWidget(self.nearby_hadith_check, 0, 5)
        top_layout.addWidget(self.preview_btn, 0, 6)
        top_layout.addWidget(self.jump_edit, 1, 0, 1, 2)
        top_layout.addWidget(self.jump_btn, 1, 2)
        top_layout.addWidget(self.prev_btn, 1, 3)
        top_layout.addWidget(self.next_btn, 1, 4)
        top_layout.addWidget(self.reload_btn, 1, 5)
        top_layout.addWidget(self.undo_btn, 1, 6)
        top_layout.addWidget(self.match_warning_label, 2, 0, 1, 7)
        layout.addWidget(top_box)

        info_box = QGroupBox("Kayıt")
        info_layout = QFormLayout(info_box)
        info_layout.setVerticalSpacing(12)
        info_layout.setHorizontalSpacing(12)
        self.id_label = QLabel("-")
        self.ref_label = QLabel("-")
        self.source_label = QLabel("-")
        self.duplicate_label = QLabel("-")
        self.status_combo = QComboBox()
        for value in STATUS_VALUES:
            self.status_combo.addItem(STATUS_LABELS.get(value, value), value)
        self.status_combo.setMaximumWidth(220)
        self.priority_combo = QComboBox()
        self.priority_combo.addItem("Normal", 1)
        self.priority_combo.addItem("Sık", 2)
        self.priority_combo.addItem("Daha sık", 3)
        self.priority_combo.setCurrentIndex(0)
        self.priority_combo.setFixedWidth(140)
        self.notes_edit = QTextEdit()
        self.notes_edit.setFixedHeight(44)
        self.notes_edit.setMaximumHeight(44)
        self.notes_edit.setMaximumWidth(260)
        self.book_ref_tr_edit = QTextEdit()
        self.book_ref_tr_edit.setFixedHeight(50)
        self.book_ref_en_edit = QTextEdit()
        self.book_ref_en_edit.setFixedHeight(50)
        self.ayah_source_edit = QTextEdit()
        self.ayah_source_edit.setFixedHeight(72)
        self.ayah_source_edit.setReadOnly(True)
        self.hadith_quality_edit = QTextEdit()
        self.hadith_quality_edit.setFixedHeight(56)
        self.hadith_quality_edit.setReadOnly(True)
        self.hadith_source_edit = QTextEdit()
        self.hadith_source_edit.setFixedHeight(56)
        self.hadith_source_edit.setReadOnly(True)
        self.esma_name_edit = QTextEdit()
        self.esma_name_edit.setMinimumHeight(80)
        self.ar_edit = QTextEdit()
        self.tr_edit = QTextEdit()
        self.en_edit = QTextEdit()
        self.tr_alt_edit = QTextEdit()
        self.en_alt_edit = QTextEdit()
        for widget in (self.ar_edit, self.tr_edit, self.en_edit):
            widget.setMinimumHeight(120)
        for widget in (self.tr_alt_edit, self.en_alt_edit):
            widget.setMinimumHeight(120)
        self.tr_main_check = self._build_translation_check("Ali Bulaç")
        self.tr_alt_check = self._build_translation_check("Diyanet")
        self.en_main_check = self._build_translation_check("Saheeh International")
        self.en_alt_check = self._build_translation_check("Maududi")
        self.tr_main_check.setChecked(True)
        self.en_main_check.setChecked(True)
        self.tr_main_check.toggled.connect(lambda checked: self._sync_translation_checks("tr", checked, True))
        self.tr_alt_check.toggled.connect(lambda checked: self._sync_translation_checks("tr", checked, False))
        self.en_main_check.toggled.connect(lambda checked: self._sync_translation_checks("en", checked, True))
        self.en_alt_check.toggled.connect(lambda checked: self._sync_translation_checks("en", checked, False))
        self.ar_font_spin = self._build_font_spin()
        self.esma_name_font_spin = self._build_font_spin()
        self.tr_font_spin = self._build_font_spin()
        self.en_font_spin = self._build_font_spin()
        self.tr_alt_font_spin = self._build_font_spin()
        self.en_alt_font_spin = self._build_font_spin()
        self.ar_font_spin.setValue(18)
        self.esma_name_font_spin.setValue(22)
        self._bind_font_size(self.esma_name_font_spin, self.esma_name_edit)
        self._bind_font_size(self.ar_font_spin, self.ar_edit)
        self._bind_font_size(self.tr_font_spin, self.tr_edit)
        self._bind_font_size(self.en_font_spin, self.en_edit)
        self._bind_font_size(self.tr_alt_font_spin, self.tr_alt_edit)
        self._bind_font_size(self.en_alt_font_spin, self.en_alt_edit)

        self.ayah_source_row = self._labeled_editor("Ayet kaynak ozeti", self.ayah_source_edit)
        self.esma_name_row = self._labeled_editor_with_font("Esma adı / Arapça isim", self.esma_name_font_spin, self.esma_name_edit)
        self.hadith_summary_row = QWidget()
        hadith_summary_layout = QHBoxLayout(self.hadith_summary_row)
        hadith_summary_layout.setContentsMargins(0, 0, 0, 0)
        hadith_summary_layout.setSpacing(12)
        hadith_summary_layout.addWidget(self._labeled_editor("Hadis eşleşme özeti", self.hadith_quality_edit))
        hadith_summary_layout.addWidget(self._labeled_editor("Hadis kaynak ozeti", self.hadith_source_edit))
        self.tr_translation_row = self._two_editor_choice_row(
            "Türkçe ana kaynak",
            self.tr_main_check,
            self.tr_font_spin,
            self.tr_edit,
            "Türkçe alternatif kaynak",
            self.tr_alt_check,
            self.tr_alt_font_spin,
            self.tr_alt_edit,
        )
        self.en_translation_row = self._two_editor_choice_row(
            "İngilizce ana kaynak",
            self.en_main_check,
            self.en_font_spin,
            self.en_edit,
            "İngilizce alternatif kaynak",
            self.en_alt_check,
            self.en_alt_font_spin,
            self.en_alt_edit,
        )

        identity_row = QWidget()
        identity_layout = QHBoxLayout(identity_row)
        identity_layout.setContentsMargins(0, 0, 0, 0)
        identity_layout.setSpacing(16)
        identity_layout.addWidget(QLabel("Kimlik"))
        identity_layout.addWidget(self.id_label, 1)
        identity_layout.addWidget(QLabel("Referans"))
        identity_layout.addWidget(self.ref_label, 1)
        info_layout.addRow(identity_row)
        info_layout.addRow("Kaynak", self.source_label)
        info_layout.addRow("Benzerlik", self.duplicate_label)
        info_layout.addRow("Durum", self.status_combo)
        priority_notes_row = QWidget()
        priority_notes_layout = QHBoxLayout(priority_notes_row)
        priority_notes_layout.setContentsMargins(0, 0, 0, 0)
        priority_notes_layout.setSpacing(10)
        priority_notes_layout.addWidget(QLabel("Öncelik"))
        priority_notes_layout.addWidget(self.priority_combo)
        priority_notes_layout.addStretch(1)
        priority_notes_layout.addWidget(QLabel("Not"))
        priority_notes_layout.addWidget(self.notes_edit)
        info_layout.addRow(priority_notes_row)
        info_layout.addRow("Ayet kaynak", self.ayah_source_row)
        info_layout.addRow("Hadis özeti", self.hadith_summary_row)
        info_layout.addRow(self.esma_name_row)
        info_layout.addRow("Arapça metin", self._editor_with_font_row(self.ar_font_spin, self.ar_edit))
        info_layout.addRow("Türkçe metin", self.tr_translation_row)
        info_layout.addRow("İngilizce metin", self.en_translation_row)
        layout.addWidget(info_box, 1)

        buttons = QHBoxLayout()
        buttons.setSpacing(10)
        self.save_btn = QPushButton("Kaydet")
        self.save_btn.clicked.connect(self._save_current)
        self.approve_btn = QPushButton("Onayla")
        self.approve_btn.clicked.connect(lambda: self._save_current("approved"))
        self.unapprove_btn = QPushButton("Onayi kaldir")
        self.unapprove_btn.clicked.connect(lambda: self._save_current("needs_review"))
        buttons.addWidget(self.save_btn)
        buttons.addWidget(self.approve_btn)
        buttons.addWidget(self.unapprove_btn)
        layout.addLayout(buttons)

    def refresh(self) -> None:
        self.repository.reload()
        self._current_kind = str(self.kind_combo.currentData() or "ayah")
        self._records = self.repository.list_archive_records(self._current_kind)
        cursor = min(self.repository.get_cursor(self._current_kind), max(0, len(self._records) - 1))
        self.repository.set_cursor(self._current_kind, cursor)
        self.summary_label.setText(f"{len(self._records)} kayıt | cursor: {cursor + 1 if self._records else 0}")
        self._current_record = self._records[cursor] if self._records else None
        self._load_record()

    def _load_record(self) -> None:
        record = self._current_record
        hadith_visible = isinstance(record, HadithRecord)
        esma_visible = isinstance(record, EsmaRecord)
        self.book_ref_tr_edit.setVisible(False)
        self.book_ref_en_edit.setVisible(False)
        self.ayah_source_row.setVisible(not hadith_visible)
        self._set_row_visible(self.hadith_summary_row, hadith_visible)
        self._set_row_visible(self.esma_name_row, esma_visible)
        self._configure_translation_mode(hadith_visible, esma_visible)
        self._set_translation_alt_visible(not hadith_visible and not esma_visible)
        if record is None:
            self.nearby_hadith_check.setChecked(False)
            self.match_warning_label.setText("")
            for label in (self.id_label, self.ref_label, self.source_label, self.duplicate_label):
                label.setText("-")
            for edit in (
                self.notes_edit,
                self.esma_name_edit,
                self.ar_edit,
                self.tr_edit,
                self.en_edit,
                self.book_ref_tr_edit,
                self.book_ref_en_edit,
                self.ayah_source_edit,
                self.tr_alt_edit,
                self.en_alt_edit,
                self.hadith_quality_edit,
                self.hadith_source_edit,
            ):
                edit.setPlainText("")
            return
        record.duplicate_info = self.repository.build_duplicate_info(record)
        self.id_label.setText(record.id)
        self.ref_label.setText(record.ref)
        self.nearby_hadith_check.setChecked(self._is_nearby_hadith(record))
        self.match_warning_label.setText(self._build_match_warning(record))
        source_status = STATUS_LABELS.get(record.status, record.status)
        self.source_label.setText(f"{record.source_info.label or '-'} | {record.source_info.fetch_status} | {source_status}")
        duplicate_bits = []
        if record.duplicate_info.exists_in_archive:
            duplicate_bits.append("arşivde var")
        if record.duplicate_info.exists_in_approved:
            duplicate_bits.append("onaylıda var")
        if record.duplicate_info.exact_duplicate:
            duplicate_bits.append("tam aynı kayıt")
        if record.duplicate_info.possible_duplicate:
            duplicate_bits.append("benzer kayıt")
        match_count = len(record.duplicate_info.archive_matches) + len(record.duplicate_info.approved_matches)
        self.duplicate_label.setText(f"{', '.join(duplicate_bits) or '-'} | eşleşme: {match_count}")
        self.status_combo.setCurrentIndex(max(0, self.status_combo.findData(record.status)))
        self.priority_combo.setCurrentIndex(max(0, self.priority_combo.findData(self._normalize_priority(record.priority))))
        self.notes_edit.setPlainText(record.notes)
        self.esma_name_edit.setPlainText("")
        self.ar_edit.setPlainText(record.ar)
        self.tr_edit.setPlainText(record.tr)
        self.en_edit.setPlainText(record.en)
        if isinstance(record, HadithRecord):
            self.book_ref_tr_edit.setPlainText(record.book_reference_tr)
            self.book_ref_en_edit.setPlainText(record.book_reference_en)
            self.ayah_source_edit.setPlainText("")
            self.tr_alt_edit.setPlainText("")
            self.en_alt_edit.setPlainText("")
            self.tr_main_check.setChecked(True)
            self.en_main_check.setChecked(True)
            self.hadith_quality_edit.setPlainText(self._extract_hadith_quality_summary(record))
            self.hadith_source_edit.setPlainText(self._extract_hadith_source_summary(record))
        elif isinstance(record, EsmaRecord):
            self.book_ref_tr_edit.setPlainText("")
            self.book_ref_en_edit.setPlainText("")
            self.ayah_source_edit.setPlainText(self._extract_esma_summary(record))
            self.esma_name_edit.setPlainText(record.arabic_name)
            self.tr_alt_edit.setPlainText("")
            self.en_alt_edit.setPlainText("")
            self.tr_main_check.setChecked(True)
            self.en_main_check.setChecked(True)
            self.hadith_quality_edit.setPlainText("")
            self.hadith_source_edit.setPlainText("")
        else:
            self.book_ref_tr_edit.setPlainText("")
            self.book_ref_en_edit.setPlainText("")
            self.ayah_source_edit.setPlainText(self._extract_ayah_source_summary(record))
            self.esma_name_edit.setPlainText("")
            tr_alt_text = self._extract_ayah_alt_text(record, "tr")
            en_alt_text = self._extract_ayah_alt_text(record, "en")
            self.tr_alt_edit.setPlainText(tr_alt_text)
            self.en_alt_edit.setPlainText(en_alt_text)
            self._restore_translation_selection(record, "tr", tr_alt_text)
            self._restore_translation_selection(record, "en", en_alt_text)
            self.hadith_quality_edit.setPlainText("")
            self.hadith_source_edit.setPlainText("")

    def _save_current(self, force_status: str | None = None) -> None:
        record = self._current_record
        if record is None:
            return
        status = force_status or str(self.status_combo.currentData() or "needs_review")
        updated = replace(
            record,
            status=status,
            priority=int(self.priority_combo.currentData() or 1),
            notes=self.notes_edit.toPlainText().strip(),
            ar=self.ar_edit.toPlainText().strip(),
            tr=self._selected_translation_text("tr"),
            en=self._selected_translation_text("en"),
        )
        if isinstance(updated, AyahRecord):
            raw = dict(updated.raw or {})
            raw["text_tr_alt"] = self.tr_alt_edit.toPlainText().strip()
            raw["text_en_alt"] = self.en_alt_edit.toPlainText().strip()
            raw["selected_translation"] = {
                "tr": "alt" if self.tr_alt_check.isChecked() else "main",
                "en": "alt" if self.en_alt_check.isChecked() else "main",
            }
            updated = replace(updated, raw=raw)
        if isinstance(updated, HadithRecord):
            updated = replace(
                updated,
                book_reference_tr=self.book_ref_tr_edit.toPlainText().strip(),
                book_reference_en=self.book_ref_en_edit.toPlainText().strip(),
            )
        if isinstance(updated, EsmaRecord):
            updated = replace(
                updated,
                arabic_name=self.esma_name_edit.toPlainText().strip(),
            )
        if updated.status == "approved" and not updated.approved_at:
            updated = replace(
                updated,
                approved_at=datetime.now(timezone.utc).replace(microsecond=0).isoformat(),
            )
        try:
            self.repository.save_record(updated)
        except StorageConflictError as exc:
            QMessageBox.critical(self, "Hash catismasi", str(exc))
            return
        except Exception as exc:
            QMessageBox.critical(self, "Kaydetme hatası", str(exc))
            return
        self.refresh()

    def _move(self, delta: int) -> None:
        if not self._records:
            return
        cursor = min(max(self.repository.get_cursor(self._current_kind) + delta, 0), len(self._records) - 1)
        self.repository.set_cursor(self._current_kind, cursor)
        self._current_record = self._records[cursor]
        self._load_record()
        self.summary_label.setText(f"{len(self._records)} kayıt | cursor: {cursor + 1}")

    def _jump_to_record(self) -> None:
        target = self.jump_edit.text().strip()
        if not target:
            return
        for index, record in enumerate(self._records):
            if target in {record.id, record.ref}:
                self.repository.set_cursor(self._current_kind, index)
                self._current_record = record
                self._load_record()
                self.summary_label.setText(f"{len(self._records)} kayıt | cursor: {index + 1}")
                return
        QMessageBox.information(self, "Bulunamadi", "Kayıt bulunamadı.")

    def _on_kind_changed(self, *_args) -> None:
        self.refresh()

    def _undo_last(self) -> None:
        if not self.repository.undo_last_write():
            QMessageBox.information(self, "Undo", "Geri alinacak yazım yok.")
            return
        self.refresh()

    def _open_mobile_preview(self) -> None:
        if self._preview_window is None:
            self._preview_window = MobilePreviewWindow(self.repository)
        else:
            self._preview_window.refresh()
        self._preview_window.show()
        self._preview_window.raise_()
        self._preview_window.activateWindow()

    def _build_font_spin(self) -> QSpinBox:
        spin = QSpinBox()
        spin.setRange(14, 36)
        spin.setValue(14)
        spin.setSuffix(" pt")
        spin.setMaximumWidth(90)
        return spin

    def _bind_font_size(self, spin: QSpinBox, editor: QTextEdit) -> None:
        spin.valueChanged.connect(lambda value: editor.setStyleSheet(f"font-size: {value}pt;"))
        editor.setStyleSheet(f"font-size: {spin.value()}pt;")

    def _editor_with_font_row(self, spin: QSpinBox, editor: QTextEdit) -> QWidget:
        panel = QWidget()
        panel_layout = QVBoxLayout(panel)
        panel_layout.setContentsMargins(0, 0, 0, 0)
        top = QHBoxLayout()
        top.setContentsMargins(0, 0, 0, 0)
        top.addWidget(QLabel("Yazi boyutu"))
        top.addWidget(spin)
        top.addStretch(1)
        panel_layout.addLayout(top)
        panel_layout.addWidget(editor)
        return panel

    def _labeled_editor_with_font(self, title: str, spin: QSpinBox, editor: QTextEdit) -> QWidget:
        panel = QWidget()
        panel.setStyleSheet("background:#fafafa; border:1px solid #d8d8d8; border-radius:8px;")
        panel_layout = QVBoxLayout(panel)
        panel_layout.setContentsMargins(8, 8, 8, 8)
        panel_layout.setSpacing(8)
        top = QHBoxLayout()
        top.setContentsMargins(0, 0, 0, 0)
        title_label = QLabel(title)
        title_label.setStyleSheet("font-size: 14pt; font-weight: 600;")
        top.addWidget(title_label)
        top.addStretch(1)
        top.addWidget(QLabel("Yazi boyutu"))
        top.addWidget(spin)
        panel_layout.addLayout(top)
        panel_layout.addWidget(editor)
        return panel

    def _two_editor_choice_row(
        self,
        left_title: str,
        left_check: QCheckBox,
        left_spin: QSpinBox,
        left_editor: QTextEdit,
        right_title: str,
        right_check: QCheckBox,
        right_spin: QSpinBox,
        right_editor: QTextEdit,
    ) -> QWidget:
        row = QWidget()
        row_layout = QHBoxLayout(row)
        row_layout.setContentsMargins(0, 0, 0, 0)
        row_layout.setSpacing(12)
        left_panel = self._choice_editor_panel(left_title, left_check, left_spin, left_editor)
        right_panel = self._choice_editor_panel(right_title, right_check, right_spin, right_editor)
        row.left_panel = left_panel
        row.right_panel = right_panel
        row_layout.addWidget(left_panel)
        row_layout.addWidget(right_panel)
        return row

    def _choice_editor_panel(self, title: str, check: QCheckBox, spin: QSpinBox, editor: QTextEdit) -> QWidget:
        panel = QWidget()
        panel.setStyleSheet("background:#fafafa; border:1px solid #d8d8d8; border-radius:8px;")
        panel_layout = QVBoxLayout(panel)
        panel_layout.setContentsMargins(8, 8, 8, 8)
        panel_layout.setSpacing(8)
        title_row = QHBoxLayout()
        title_row.setContentsMargins(0, 0, 0, 0)
        title_row.setSpacing(8)
        label = QLabel(title)
        label.setStyleSheet("font-size: 14pt; font-weight: 600;")
        panel.title_label = label
        title_row.addWidget(check)
        title_row.addWidget(label)
        title_row.addStretch(1)
        title_row.addWidget(QLabel("Yazi boyutu"))
        title_row.addWidget(spin)
        panel_layout.addLayout(title_row)
        panel_layout.addWidget(editor)
        return panel

    def _labeled_editor(self, label: str, editor: QTextEdit) -> QWidget:
        panel = QWidget()
        panel.setStyleSheet("background:#fafafa; border:1px solid #d8d8d8; border-radius:8px;")
        panel_layout = QVBoxLayout(panel)
        panel_layout.setContentsMargins(8, 8, 8, 8)
        panel_layout.setSpacing(8)
        title = QLabel(label)
        title.setStyleSheet("font-size: 14pt; font-weight: 600;")
        panel_layout.addWidget(title)
        panel_layout.addWidget(editor)
        return panel

    def _build_status_check(self, label: str) -> QCheckBox:
        check = QCheckBox(label)
        check.setEnabled(False)
        check.setStyleSheet("font-size: 14pt; font-weight: 600;")
        return check

    def _build_translation_check(self, label: str) -> QCheckBox:
        check = QCheckBox(label)
        check.setStyleSheet("font-size: 14pt; font-weight: 600;")
        return check

    def _normalize_priority(self, value: int) -> int:
        try:
            priority = int(value)
        except (TypeError, ValueError):
            return 1
        return max(1, min(3, priority))

    def _set_row_visible(self, widget: QWidget, visible: bool) -> None:
        widget.setVisible(visible)

    def _set_translation_alt_visible(self, visible: bool) -> None:
        self.tr_translation_row.right_panel.setVisible(visible)
        self.en_translation_row.right_panel.setVisible(visible)
        if not visible:
            self.tr_alt_edit.clear()
            self.en_alt_edit.clear()
            self.tr_main_check.setChecked(True)
            self.en_main_check.setChecked(True)

    def _configure_translation_mode(self, is_hadith: bool, is_esma: bool) -> None:
        show_choices = not is_hadith and not is_esma
        self.tr_main_check.setVisible(show_choices)
        self.en_main_check.setVisible(show_choices)
        self.tr_alt_check.setVisible(show_choices)
        self.en_alt_check.setVisible(show_choices)
        if is_hadith:
            self.tr_translation_row.left_panel.title_label.setText("Hadis Türkçe metni")
            self.en_translation_row.left_panel.title_label.setText("Hadis İngilizce metni")
        elif is_esma:
            self.tr_translation_row.left_panel.title_label.setText("Esma Türkçe açıklaması")
            self.en_translation_row.left_panel.title_label.setText("Esma İngilizce açıklaması")
        else:
            self.tr_translation_row.left_panel.title_label.setText("Türkçe ana kaynak")
            self.tr_translation_row.right_panel.title_label.setText("Türkçe alternatif kaynak")
            self.en_translation_row.left_panel.title_label.setText("İngilizce ana kaynak")
            self.en_translation_row.right_panel.title_label.setText("İngilizce alternatif kaynak")
            self.tr_main_check.setText("Ali Bulaç")
            self.tr_alt_check.setText("Diyanet")
            self.en_main_check.setText("Saheeh International")
            self.en_alt_check.setText("Maududi")

    def _sync_translation_checks(self, language: str, checked: bool, main_side: bool) -> None:
        if not checked:
            return
        if language == "tr":
            if main_side:
                self.tr_alt_check.blockSignals(True)
                self.tr_alt_check.setChecked(False)
                self.tr_alt_check.blockSignals(False)
            else:
                self.tr_main_check.blockSignals(True)
                self.tr_main_check.setChecked(False)
                self.tr_main_check.blockSignals(False)
        else:
            if main_side:
                self.en_alt_check.blockSignals(True)
                self.en_alt_check.setChecked(False)
                self.en_alt_check.blockSignals(False)
            else:
                self.en_main_check.blockSignals(True)
                self.en_main_check.setChecked(False)
                self.en_main_check.blockSignals(False)

    def _restore_translation_selection(self, record: BaseRecord, language: str, alt_text: str) -> None:
        selected = ""
        if isinstance(record.raw, dict):
            selection = record.raw.get("selected_translation")
            if isinstance(selection, dict):
                selected = str(selection.get(language) or "")
        use_alt = bool(selected == "alt" or (alt_text.strip() and getattr(record, language).strip() == alt_text.strip()))
        if language == "tr":
            self.tr_alt_check.setChecked(use_alt)
            self.tr_main_check.setChecked(not use_alt)
        else:
            self.en_alt_check.setChecked(use_alt)
            self.en_main_check.setChecked(not use_alt)

    def _selected_translation_text(self, language: str) -> str:
        if self._current_kind in {"hadith", "esma"}:
            return self.tr_edit.toPlainText().strip() if language == "tr" else self.en_edit.toPlainText().strip()
        if language == "tr":
            return self.tr_alt_edit.toPlainText().strip() if self.tr_alt_check.isChecked() else self.tr_edit.toPlainText().strip()
        return self.en_alt_edit.toPlainText().strip() if self.en_alt_check.isChecked() else self.en_edit.toPlainText().strip()

    def _extract_esma_summary(self, record: EsmaRecord) -> str:
        source_basis = []
        if isinstance(record.raw, dict):
            raw_basis = record.raw.get("sourceBasis")
            if isinstance(raw_basis, list):
                source_basis = [str(item).strip() for item in raw_basis if str(item).strip()]
        parts = [
            f"Esma no: {record.esma_number or '-'}",
            f"Slug: {record.slug or '-'}",
            f"Arapça ad: {record.arabic_name or '-'}",
            f"TR okunuş: {record.latin_tr or '-'}",
            f"EN okunuş: {record.latin_en or '-'}",
        ]
        if source_basis:
            parts.append("Kaynak: " + " | ".join(source_basis[:2]))
        return "\n".join(parts)

    def _extract_ayah_source_summary(self, record: BaseRecord) -> str:
        source = record.raw.get("source") if isinstance(record.raw, dict) else None
        if not isinstance(source, dict):
            return record.source_info.label or "-"
        parts = [
            f"Arapça: {source.get('arabic') or '-'}",
            f"TR ana: {source.get('tr') or '-'}",
            f"TR alternatif: {source.get('trAlt') or source.get('tr_alternative') or '-'}",
            f"EN ana: {source.get('en') or '-'}",
            f"EN alternatif: {source.get('enAlt') or source.get('en_alternative') or '-'}",
        ]
        return "\n".join(parts)

    def _extract_ayah_alt_text(self, record: BaseRecord, language: str) -> str:
        if isinstance(record.raw, dict):
            direct = str(record.raw.get("text_tr_alt" if language == "tr" else "text_en_alt") or "").strip()
            if direct:
                return direct
        if not isinstance(record.raw, dict):
            return ""
        parts: list[str] = []
        for item in record.raw.get("ayahs", []):
            if not isinstance(item, dict):
                continue
            ayah_no = item.get("ayah")
            alternatives = item.get("alternatives")
            alt = None
            if isinstance(alternatives, dict):
                alt = alternatives.get("tr_diyanet_tanzil") if language == "tr" else alternatives.get("en_maududi")
            if not isinstance(alt, dict):
                alt = item.get("trAlt") if language == "tr" else item.get("enAlt")
            text = str(alt.get("text") if isinstance(alt, dict) else "").strip()
            if text:
                if len(record.raw.get("ayahs", [])) > 1 and ayah_no is not None:
                    text = f"[{ayah_no}] {text}"
                parts.append(text)
        return "\n\n".join(parts)

    def _extract_hadith_quality_summary(self, record: BaseRecord) -> str:
        quality = record.raw.get("quality") if isinstance(record.raw, dict) else None
        input_block = record.raw.get("input") if isinstance(record.raw, dict) else None
        if not isinstance(quality, dict):
            return record.source_info.fetch_status or "-"
        match_status = quality.get("matchStatus") or (input_block.get("matchStatus") if isinstance(input_block, dict) else "-")
        parts = [
            f"Eşleşme güveni: {quality.get('matchConfidence') or '-'}",
            f"Eşleşme durumu: {match_status or '-'}",
            f"Semantik: {quality.get('semanticMatch') or '-'}",
            f"Ravi: {quality.get('narratorMatch') or '-'}",
            f"Konu: {quality.get('topicMatch') or '-'}",
        ]
        notes = quality.get("notes")
        if isinstance(notes, list) and notes:
            parts.append("Notlar: " + "; ".join(str(note) for note in notes[:3]))
        return "\n".join(parts)

    def _extract_hadith_source_summary(self, record: BaseRecord) -> str:
        source_info = record.raw.get("sourceInfo") if isinstance(record.raw, dict) else None
        if not isinstance(source_info, dict):
            return record.source_info.label or "-"
        display = source_info.get("display") if isinstance(source_info.get("display"), dict) else {}
        sunnah = source_info.get("sunnah") if isinstance(source_info.get("sunnah"), dict) else {}
        chapter = source_info.get("chapter") if isinstance(source_info.get("chapter"), dict) else {}
        primary = source_info.get("primaryCollection") if isinstance(source_info.get("primaryCollection"), dict) else {}
        target_no, candidate_no = self._extract_hadith_number_pair(record)
        number_line = "-"
        if target_no is not None and candidate_no is not None:
            number_line = f"Hedef {target_no} / aday {candidate_no} / fark {candidate_no - target_no:+d}"
        parts = [
            f"Koleksiyon: {source_info.get('label') or primary.get('title_tr') or '-'}",
            f"Bolum: {chapter.get('title_tr') or '-'}",
            f"No karsilastirma: {number_line}",
            f"TR kaynak: {display.get('tr') or '-'}",
            f"EN kaynak: {display.get('en') or '-'}",
            f"Sunnah URL: {sunnah.get('candidateUrl') or '-'}",
        ]
        return "\n".join(parts)

    def _extract_hadith_number_pair(self, record: BaseRecord) -> tuple[int | None, int | None]:
        if not isinstance(record, HadithRecord):
            return None, None
        source_info = record.raw.get("sourceInfo") if isinstance(record.raw, dict) else None
        input_block = record.raw.get("input") if isinstance(record.raw, dict) else None
        if not isinstance(source_info, dict):
            return record.hadith_number, None
        sunnah = source_info.get("sunnah")
        if not isinstance(sunnah, dict):
            return record.hadith_number, None
        try:
            candidate_no = int(sunnah.get("candidateNo"))
        except (TypeError, ValueError):
            candidate_no = None
        try:
            target_no = int(record.hadith_number or (input_block.get("hadithNo_diyanet") if isinstance(input_block, dict) else None))
        except (TypeError, ValueError):
            target_no = None
        return target_no, candidate_no

    def _is_nearby_hadith(self, record: BaseRecord) -> bool:
        if not isinstance(record, HadithRecord):
            return False
        fetch_status = str(record.source_info.fetch_status or "").strip().lower()
        if fetch_status == "local_hadith_nearby":
            return True
        source_info = record.raw.get("sourceInfo") if isinstance(record.raw, dict) else None
        if not isinstance(source_info, dict):
            return False
        sunnah = source_info.get("sunnah")
        input_block = record.raw.get("input")
        if not isinstance(sunnah, dict) or not isinstance(input_block, dict):
            return False
        try:
            candidate_no = int(sunnah.get("candidateNo"))
            target_no = int(record.hadith_number or input_block.get("hadithNo_diyanet"))
            return candidate_no != target_no
        except (TypeError, ValueError):
            return False

    def _build_match_warning(self, record: BaseRecord) -> str:
        if not isinstance(record, HadithRecord):
            return ""
        if self._is_nearby_hadith(record):
            return "Uyarı: Bu kayıt yakın hadis numarasından gelmiş olabilir. Onaydan önce metin eşleşmesini kontrol et."
        quality = record.raw.get("quality") if isinstance(record.raw, dict) else None
        if isinstance(quality, dict):
            confidence = str(quality.get("matchConfidence") or "").lower()
            match_status = str(quality.get("matchStatus") or "").lower()
            if confidence in {"low", "medium"} or "manual" in match_status or "light" in match_status:
                return "Uyarı: Hadis eşleşmesi kesin olmayabilir. Kaynak ve metin uyumunu kontrol et."
        return ""


