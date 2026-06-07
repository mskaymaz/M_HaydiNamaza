from __future__ import annotations

from PySide6.QtCore import Qt
from PySide6.QtWidgets import (
    QCheckBox,
    QComboBox,
    QFormLayout,
    QGroupBox,
    QHBoxLayout,
    QLabel,
    QLineEdit,
    QProgressBar,
    QPushButton,
    QSizePolicy,
    QTextEdit,
    QVBoxLayout,
    QWidget,
)

from core.models import STATUS_VALUES
from ui.add_panel import AddPanel, STATUS_LABELS, TEXT_EDITOR_BASE_HEIGHT
from ui.scale import scale


class SimpleAddPanel(AddPanel):
    """Small add screen that reuses the existing add workflow."""

    def _build_ui(self) -> None:
        layout = QVBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(0)

        top_row = QHBoxLayout()
        top_row.setContentsMargins(0, 0, 0, 0)
        top_row.setSpacing(4)
        self.kind_combo = QComboBox()
        self.kind_combo.addItem("Ayet", "ayah")
        self.kind_combo.addItem("Hadis", "hadith")
        self.kind_combo.currentIndexChanged.connect(self._toggle_kind_fields)

        self.reference_edit = QLineEdit()
        self.reference_edit.setPlaceholderText("001/004, 018/001-010 veya 706")
        self.reference_edit.setFixedWidth(150)

        self.check_btn = QPushButton("Getir")
        self.check_btn.clicked.connect(self._check_and_fetch)
        self.undo_btn = QPushButton("Geri al")
        self.undo_btn.clicked.connect(self._undo_last)

        top_row.addWidget(QLabel("Tür"))
        top_row.addWidget(self.kind_combo)
        top_row.addWidget(QLabel("Referans"))
        top_row.addWidget(self.reference_edit)
        top_row.addWidget(self.check_btn)
        top_row.addWidget(self.undo_btn)
        layout.addLayout(top_row)

        self.fetch_status_label = QLabel("Veri durumu: henüz kontrol edilmedi")
        self.fetch_status_label.setWordWrap(True)
        self.match_warning_label = QLabel("")
        self.match_warning_label.setWordWrap(True)
        self.match_warning_label.setStyleSheet("font-weight: 700; color: #8a4b00;")
        self.fetch_progress = QProgressBar()
        self.fetch_progress.setRange(0, 0)
        self.fetch_progress.setVisible(False)
        self.fetch_progress.setFixedHeight(scale(12))
        layout.addWidget(self.fetch_status_label)
        layout.addWidget(self.match_warning_label)
        layout.addWidget(self.fetch_progress)

        identity_row = QHBoxLayout()
        identity_row.setContentsMargins(0, 0, 0, 0)
        identity_row.setSpacing(4)
        self.id_label = QLabel("-")
        self.ref_label = QLabel("-")
        identity_row.addWidget(QLabel("Kimlik"))
        identity_row.addWidget(self.id_label, 1)
        identity_row.addWidget(QLabel("Referans"))
        identity_row.addWidget(self.ref_label, 1)
        layout.addLayout(identity_row)

        self.ar_edit = self._new_text_editor()
        self.tr_edit = self._new_text_editor()
        self.en_edit = self._new_text_editor()
        self.tr_alt_edit = self._new_text_editor()
        self.en_alt_edit = self._new_text_editor()
        self._expanding_text_edits = [
            self.ar_edit,
            self.tr_edit,
            self.en_edit,
            self.tr_alt_edit,
            self.en_alt_edit,
        ]

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
        self.tr_font_spin = self._build_font_spin()
        self.en_font_spin = self._build_font_spin()
        self.tr_alt_font_spin = self._build_font_spin()
        self.en_alt_font_spin = self._build_font_spin()
        self.ar_font_spin.setValue(18)
        self._bind_font_size(self.ar_font_spin, self.ar_edit)
        self._bind_font_size(self.tr_font_spin, self.tr_edit)
        self._bind_font_size(self.en_font_spin, self.en_edit)
        self._bind_font_size(self.tr_alt_font_spin, self.tr_alt_edit)
        self._bind_font_size(self.en_alt_font_spin, self.en_alt_edit)

        self.ar_source_label = self._build_source_label(14)
        self.tr_source_label = self._build_source_label(12)
        self.tr_alt_source_label = self._build_source_label(12)
        self.en_source_label = self._build_source_label(12)
        self.en_alt_source_label = self._build_source_label(12)

        self.ayah_source_edit = QTextEdit()
        self.ayah_source_edit.setFixedHeight(scale(36))
        self.ayah_source_edit.setReadOnly(True)
        self.hadith_quality_edit = QTextEdit()
        self.hadith_quality_edit.setFixedHeight(scale(28))
        self.hadith_quality_edit.setReadOnly(True)
        self.hadith_source_edit = QTextEdit()
        self.hadith_source_edit.setFixedHeight(scale(28))
        self.hadith_source_edit.setReadOnly(True)
        self.ayah_source_row = self._labeled_editor("Ayet kaynak özeti", self.ayah_source_edit)
        self.hadith_summary_row = QWidget()
        self.hadith_summary_row.setSizePolicy(QSizePolicy.Preferred, QSizePolicy.Fixed)
        hadith_summary_layout = QHBoxLayout(self.hadith_summary_row)
        hadith_summary_layout.setContentsMargins(0, 0, 0, 0)
        hadith_summary_layout.setSpacing(0)
        hadith_summary_layout.addWidget(self._labeled_editor("Hadis eşleşme özeti", self.hadith_quality_edit))
        hadith_summary_layout.addWidget(self._labeled_editor("Hadis kaynak özeti", self.hadith_source_edit))

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

        text_form = QFormLayout()
        text_form.setContentsMargins(0, 0, 0, 0)
        text_form.setVerticalSpacing(0)
        text_form.setHorizontalSpacing(0)
        text_form.addRow("Ayet kaynak", self.ayah_source_row)
        text_form.addRow("Hadis özeti", self.hadith_summary_row)
        self.ayah_source_label = text_form.labelForField(self.ayah_source_row)
        self.hadith_summary_label = text_form.labelForField(self.hadith_summary_row)
        text_form.addRow("Arapça metin", self._editor_with_font_row(self.ar_font_spin, self.ar_edit))
        text_form.addRow("Türkçe metin", self.tr_translation_row)
        text_form.addRow("İngilizce metin", self.en_translation_row)
        layout.addLayout(text_form, 1)

        self.notes_edit = QTextEdit()
        self.notes_edit.setReadOnly(True)
        self.notes_edit.setFixedHeight(scale(58))
        self.notes_box = QGroupBox("Notlar")
        self.notes_box.setCheckable(True)
        self.notes_box.setChecked(False)
        notes_layout = QVBoxLayout(self.notes_box)
        notes_layout.setContentsMargins(0, 0, 0, 0)
        notes_layout.setSpacing(0)
        notes_layout.addWidget(self.notes_edit)
        self.notes_edit.setVisible(False)
        self.notes_box.toggled.connect(self.notes_edit.setVisible)
        layout.addWidget(self.notes_box)

        bottom_row = QHBoxLayout()
        bottom_row.setContentsMargins(0, 0, 0, 0)
        bottom_row.setSpacing(4)
        self.priority_combo = QComboBox()
        self.priority_combo.addItem("Normal", 1)
        self.priority_combo.addItem("Sık", 2)
        self.priority_combo.addItem("Daha sık", 3)
        bottom_row.addWidget(QLabel("Öncelik"))
        bottom_row.addWidget(self.priority_combo)
        bottom_row.addStretch(1)
        layout.addLayout(bottom_row)

        buttons = QHBoxLayout()
        buttons.setContentsMargins(0, 0, 0, 0)
        buttons.setSpacing(4)
        self.save_btn = QPushButton("Ekle")
        self.save_btn.clicked.connect(self._approve_and_save)
        buttons.addStretch(1)
        buttons.addWidget(self.save_btn)
        layout.addLayout(buttons)

        self._build_hidden_compat_fields()
        self._toggle_kind_fields()

    def _new_text_editor(self) -> QTextEdit:
        editor = QTextEdit()
        editor.setFixedHeight(TEXT_EDITOR_BASE_HEIGHT)
        editor.setSizePolicy(QSizePolicy.Preferred, QSizePolicy.Expanding)
        return editor

    def _build_source_label(self, font_size: int) -> QLabel:
        label = QLabel("YOK")
        label.setWordWrap(False)
        label.setAlignment(Qt.AlignRight | Qt.AlignVCenter)
        label.setMinimumWidth(scale(260))
        label.setMaximumWidth(scale(520))
        label.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Fixed)
        label.setTextInteractionFlags(Qt.TextSelectableByMouse)
        self._set_source_label_font(label, font_size)
        return label

    def _set_source_label_font(self, label: QLabel, value: int) -> None:
        label.setFixedHeight(scale(42 if value >= 14 else 36))
        label.setStyleSheet(
            "background:#f7f7f7; border:1px solid #dddddd; border-radius:5px; "
            f"padding:0 8px; font-size:{value}pt;"
        )

    def _build_hidden_compat_fields(self) -> None:
        self.status_combo = QComboBox()
        for value in STATUS_VALUES:
            self.status_combo.addItem(STATUS_LABELS.get(value, value), value)

        self.book_ref_tr_edit = QTextEdit()
        self.book_ref_en_edit = QTextEdit()

        self.archive_check = QCheckBox()
        self.approved_check = QCheckBox()
        self.exact_check = QCheckBox()
        self.possible_check = QCheckBox()
        self.nearby_hadith_check = QCheckBox()

        for widget in (
            self.status_combo,
            self.book_ref_tr_edit,
            self.book_ref_en_edit,
            self.archive_check,
            self.approved_check,
            self.exact_check,
            self.possible_check,
            self.nearby_hadith_check,
        ):
            widget.setVisible(False)

    def _toggle_kind_fields(self, *_args) -> None:
        self._reset_form_for_kind_change()
        is_hadith = str(self.kind_combo.currentData() or "ayah") == "hadith"
        self.ayah_source_row.setVisible(not is_hadith)
        self.ayah_source_label.setVisible(not is_hadith)
        self.hadith_summary_row.setVisible(is_hadith)
        self.hadith_summary_label.setVisible(is_hadith)
        self._configure_translation_mode(is_hadith)
        self._set_translation_alt_visible(not is_hadith)
        if is_hadith:
            self.reference_edit.setPlaceholderText("706")
        else:
            self.reference_edit.setPlaceholderText("001/004 veya 018/001-010")

    def _selected_translation_text(self, language: str) -> str:
        if str(self.kind_combo.currentData() or "ayah") == "hadith":
            return self.tr_edit.toPlainText().strip() if language == "tr" else self.en_edit.toPlainText().strip()
        if language == "tr":
            return self.tr_alt_edit.toPlainText().strip() if self.tr_alt_check.isChecked() else self.tr_edit.toPlainText().strip()
        return self.en_alt_edit.toPlainText().strip() if self.en_alt_check.isChecked() else self.en_edit.toPlainText().strip()

    def _editor_with_font_row(self, spin, editor: QTextEdit) -> QWidget:
        panel = QWidget()
        panel.setSizePolicy(QSizePolicy.Preferred, QSizePolicy.Expanding)
        panel_layout = QVBoxLayout(panel)
        panel_layout.setContentsMargins(0, 0, 0, 0)
        panel_layout.setSpacing(0)
        top = QHBoxLayout()
        top.setContentsMargins(0, 0, 0, 0)
        top.setSpacing(4)
        top.addWidget(QLabel("Yazi boyutu"))
        top.addWidget(spin)
        top.addStretch(1)
        top.addWidget(self.ar_source_label)
        panel_layout.addLayout(top)
        panel_layout.addWidget(editor)
        return panel

    def _choice_editor_panel(self, title: str, check: QCheckBox, spin, editor: QTextEdit) -> QWidget:
        panel = QWidget()
        panel.setSizePolicy(QSizePolicy.Preferred, QSizePolicy.Expanding)
        panel.setStyleSheet("background:#fafafa; border:1px solid #d8d8d8; border-radius:8px;")
        panel_layout = QVBoxLayout(panel)
        panel_layout.setContentsMargins(0, 0, 0, 0)
        panel_layout.setSpacing(0)
        title_row = QHBoxLayout()
        title_row.setContentsMargins(0, 0, 0, 0)
        title_row.setSpacing(4)
        label = QLabel(title)
        label.setStyleSheet("font-weight: 600;")
        panel.title_label = label
        title_row.addWidget(check)
        title_row.addWidget(label)
        title_row.addWidget(QLabel("Yazi boyutu"))
        title_row.addWidget(spin)
        title_row.addStretch(1)
        title_row.addWidget(self._source_label_for_editor(editor))
        panel_layout.addLayout(title_row)

        panel_layout.addWidget(editor)
        return panel

    def _two_editor_choice_row(
        self,
        left_title: str,
        left_check: QCheckBox,
        left_spin,
        left_editor: QTextEdit,
        right_title: str,
        right_check: QCheckBox,
        right_spin,
        right_editor: QTextEdit,
    ) -> QWidget:
        row = QWidget()
        row.setSizePolicy(QSizePolicy.Preferred, QSizePolicy.Fixed)
        row_layout = QHBoxLayout(row)
        row_layout.setContentsMargins(0, 0, 0, 0)
        row_layout.setSpacing(10)
        left_panel = self._choice_editor_panel(left_title, left_check, left_spin, left_editor)
        right_panel = self._choice_editor_panel(right_title, right_check, right_spin, right_editor)
        row.left_panel = left_panel
        row.right_panel = right_panel
        row_layout.addWidget(left_panel, 1)
        row_layout.addWidget(right_panel, 1)
        return row

    def resizeEvent(self, event) -> None:
        QWidget.resizeEvent(self, event)
        is_hadith = str(self.kind_combo.currentData() or "ayah") == "hadith"
        editors = [self.ar_edit, self.tr_edit, self.en_edit] if is_hadith else list(self._expanding_text_edits)
        reserve = scale(245 if is_hadith else 270)
        available_height = max(scale(150), self.height() - reserve)
        editor_height = max(scale(70), min(scale(190), available_height // len(editors)))
        for editor in self._expanding_text_edits:
            editor.setFixedHeight(editor_height if editor in editors else TEXT_EDITOR_BASE_HEIGHT)

    def _configure_translation_mode(self, is_hadith: bool) -> None:
        self.tr_main_check.setVisible(not is_hadith)
        self.en_main_check.setVisible(not is_hadith)
        self.tr_alt_check.setVisible(not is_hadith)
        self.en_alt_check.setVisible(not is_hadith)
        self.tr_translation_row.left_panel.title_label.setVisible(not is_hadith)
        self.en_translation_row.left_panel.title_label.setVisible(not is_hadith)
        self.tr_translation_row.right_panel.title_label.setVisible(not is_hadith)
        self.en_translation_row.right_panel.title_label.setVisible(not is_hadith)
        if not is_hadith:
            self.tr_translation_row.left_panel.title_label.setText("")
            self.tr_translation_row.right_panel.title_label.setText("")
            self.en_translation_row.left_panel.title_label.setText("")
            self.en_translation_row.right_panel.title_label.setText("")
            self.tr_main_check.setText("Ali Bulaç")
            self.tr_alt_check.setText("Diyanet")
            self.en_main_check.setText("Saheeh International")
            self.en_alt_check.setText("Maududi")

    def _source_label_for_editor(self, editor: QTextEdit) -> QLabel:
        if editor is self.tr_alt_edit:
            return self.tr_alt_source_label
        if editor is self.en_alt_edit:
            return self.en_alt_source_label
        if editor is self.en_edit:
            return self.en_source_label
        return self.tr_source_label

    def _load_record(self, record) -> None:
        super()._load_record(record)
        self._refresh_readonly_metadata(record)

    def _refresh_readonly_metadata(self, record) -> None:
        raw = record.raw if isinstance(record.raw, dict) else {}
        source_info = raw.get("sourceInfo") if isinstance(raw.get("sourceInfo"), dict) else {}
        display = source_info.get("display") if isinstance(source_info.get("display"), dict) else {}
        quality = raw.get("quality") if isinstance(raw.get("quality"), dict) else {}

        self._set_source_label_value(self.ar_source_label, display.get("ar"))
        self._set_source_label_value(self.tr_source_label, display.get("tr"))
        self._set_source_label_value(self.tr_alt_source_label, display.get("tr"))
        self._set_source_label_value(self.en_source_label, display.get("en"))
        self._set_source_label_value(self.en_alt_source_label, display.get("en"))

        confidence = self._source_text(quality.get("matchConfidence") or quality.get("matchStatus"))
        self.hadith_quality_edit.setPlainText("Güven: " + confidence)
        notes = quality.get("notes")
        if isinstance(notes, list):
            note_text = "\n".join(str(note).strip() for note in notes if str(note).strip())
        else:
            note_text = str(notes or "").strip()
        self.notes_edit.setPlainText(note_text or "YOK")
        self.notes_box.setVisible(str(self.kind_combo.currentData() or "ayah") == "hadith")

    def _source_text(self, value) -> str:
        text = str(value or "").strip()
        return text if text else "YOK"

    def _set_source_label_value(self, label: QLabel, value) -> None:
        source = self._source_text(value)
        label.setToolTip(source)
        label.setText(self._compact_source_text(source))

    def _compact_source_text(self, value: str) -> str:
        return value if len(value) <= 80 else value[:77].rstrip() + "..."

    def _save_draft(self) -> None:
        self._approve_and_save()

    def _approve_and_save(self) -> None:
        self._save("approved")
