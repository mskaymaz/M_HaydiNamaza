from __future__ import annotations

from dataclasses import replace
from datetime import datetime, timezone

from PySide6.QtWidgets import (
    QApplication,
    QCheckBox,
    QComboBox,
    QFormLayout,
    QGridLayout,
    QGroupBox,
    QHBoxLayout,
    QLabel,
    QLineEdit,
    QProgressBar,
    QPushButton,
    QSizePolicy,
    QSpinBox,
    QTextEdit,
    QVBoxLayout,
    QWidget,
)

from core.fetchers import AyahFetcher, HadithFetcher
from core.models import (
    AyahRecord,
    BaseRecord,
    DuplicateCheckResult,
    HadithRecord,
    SourceInfo,
    STATUS_VALUES,
)
from core.publish_sync import sync_approved_publish
from core.reference_parser import normalize_reference
from core.storage import ContentRepository, StorageConflictError
from ui.quiet_message_box import quiet_confirm, quiet_critical, quiet_information, quiet_warning
from ui.scale import pt, scale


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

TEXT_EDITOR_BASE_HEIGHT = 30


def _fetch_status_label(status: str) -> str:
    mapping = {
        "local_archive": "Arşiv kaydı kullanıldı",
        "local_approved": "Onaylı ayet kaydı kullanıldı",
        "not_found": "Kayıt bulunamadı",
        "local_seed_exact": "Yerel Tanzil havuzundan kayıt bulundu",
        "local_seed_generated": "Yerel Tanzil havuzundan yeni kayıt oluşturuldu",
        "local_source_missing": "Yerel Tanzil havuzunda yok; tam kaynak dosyası olmadan getirilemez",
        "local_hadith_exact": "Yerel hadis havuzundan kayıt bulundu",
        "local_hadith_nearby": "Yakın hadis kaydı bulundu, kontrol gerekli",
        "local_hadith_missing": "Yerel hadis havuzunda kayıt bulunamadı",
        "local_hadith_source_missing": "Yerel hadis kaynak dosyası bulunamadi",
    }
    return mapping.get(status, status)


class AddPanel(QWidget):
    def __init__(self, repository: ContentRepository) -> None:
        super().__init__()
        self.repository = repository
        self.ayah_fetcher = AyahFetcher()
        self.hadith_fetcher = HadithFetcher()
        self._current_record: BaseRecord | None = None
        self._current_archive_record: BaseRecord | None = None
        self._current_approved_record: BaseRecord | None = None
        self._current_duplicate = DuplicateCheckResult()
        self._current_source = SourceInfo()
        self._text_resize_base_height: int | None = None
        self._expanding_text_edits: list[QTextEdit] = []
        self._build_ui()

    def _build_ui(self) -> None:
        layout = QVBoxLayout(self)
        layout.setSpacing(0)
        layout.setContentsMargins(0, 0, 0, 0)

        top_box = QGroupBox("Ekleme")
        top_box.setSizePolicy(QSizePolicy.Preferred, QSizePolicy.Maximum)
        top_layout = QGridLayout(top_box)
        top_layout.setContentsMargins(0, 0, 0, 0)
        top_layout.setHorizontalSpacing(0)
        top_layout.setVerticalSpacing(0)
        self.kind_combo = QComboBox()
        self.kind_combo.addItem("Ayet", "ayah")
        self.kind_combo.addItem("Hadis", "hadith")
        self.kind_combo.currentIndexChanged.connect(self._toggle_kind_fields)
        self.reference_edit = QLineEdit()
        self.reference_edit.setPlaceholderText("001/004, 018/001-010 veya 706")
        self.check_btn = QPushButton("Kontrol Et / Getir")
        self.check_btn.clicked.connect(self._check_and_fetch)
        self.undo_btn = QPushButton("Son Yazimi Geri Al")
        self.undo_btn.clicked.connect(self._undo_last)
        top_layout.addWidget(QLabel("Tur"), 0, 0)
        top_layout.addWidget(self.kind_combo, 0, 1)
        top_layout.addWidget(QLabel("Referans"), 0, 2)
        top_layout.addWidget(self.reference_edit, 0, 3)
        top_layout.addWidget(self.check_btn, 0, 4)
        top_layout.addWidget(self.undo_btn, 0, 5)

        badges_row = QWidget()
        badges_layout = QHBoxLayout(badges_row)
        badges_layout.setContentsMargins(0, 0, 0, 0)
        badges_layout.setSpacing(0)
        self.archive_check = self._build_status_check("Arşivde")
        self.approved_check = self._build_status_check("Onaylıda")
        self.exact_check = self._build_status_check("Tam aynı kayıt")
        self.possible_check = self._build_status_check("Benzer kayıt")
        self.nearby_hadith_check = self._build_status_check("Yakın hadis adayı")
        badges_layout.addWidget(self.archive_check)
        badges_layout.addWidget(self.approved_check)
        badges_layout.addWidget(self.exact_check)
        badges_layout.addWidget(self.possible_check)
        badges_layout.addWidget(self.nearby_hadith_check)
        badges_layout.addStretch(1)

        self.fetch_status_label = QLabel("-")
        self.fetch_status_label.setWordWrap(True)
        self.fetch_status_label.setStyleSheet(f"font-size: {pt(14)}pt; font-weight: 600; color: #0b5d8a;")
        self.match_warning_label = QLabel("")
        self.match_warning_label.setWordWrap(True)
        self.match_warning_label.setStyleSheet(f"font-size: {pt(14)}pt; font-weight: 700; color: #8a4b00;")
        self.fetch_progress = QProgressBar()
        self.fetch_progress.setRange(0, 0)
        self.fetch_progress.setVisible(False)
        self.fetch_progress.setFixedHeight(scale(16))
        top_layout.addWidget(badges_row, 1, 0, 1, 6)
        top_layout.addWidget(self.fetch_status_label, 2, 0, 1, 6)
        top_layout.addWidget(self.match_warning_label, 3, 0, 1, 6)
        top_layout.addWidget(self.fetch_progress, 4, 0, 1, 6)
        layout.addWidget(top_box)

        form_box = QGroupBox("Kayıt")
        form_box.setSizePolicy(QSizePolicy.Preferred, QSizePolicy.Expanding)
        form_box_layout = QVBoxLayout(form_box)
        form_box_layout.setContentsMargins(0, 0, 0, 0)
        form_box_layout.setSpacing(0)
        form = QFormLayout()
        form.setContentsMargins(0, 0, 0, 0)
        form.setVerticalSpacing(0)
        form.setHorizontalSpacing(0)
        text_form = QFormLayout()
        text_form.setContentsMargins(0, 0, 0, 0)
        text_form.setVerticalSpacing(0)
        text_form.setHorizontalSpacing(0)
        self.id_label = QLabel("-")
        self.ref_label = QLabel("-")
        self.status_combo = QComboBox()
        for value in STATUS_VALUES:
            self.status_combo.addItem(STATUS_LABELS.get(value, value), value)
        self.status_combo.setMaximumWidth(scale(220))
        self.priority_combo = QComboBox()
        self.priority_combo.addItem("Normal", 1)
        self.priority_combo.addItem("Sık", 2)
        self.priority_combo.addItem("Daha sık", 3)
        self.priority_combo.setCurrentIndex(0)
        self.priority_combo.setFixedWidth(scale(140))
        self.notes_edit = QTextEdit()
        self.notes_edit.setFixedHeight(scale(22))
        self.notes_edit.setMaximumHeight(scale(22))
        self.notes_edit.setMaximumWidth(scale(260))
        self.book_ref_tr_edit = QTextEdit()
        self.book_ref_tr_edit.setFixedHeight(scale(25))
        self.book_ref_en_edit = QTextEdit()
        self.book_ref_en_edit.setFixedHeight(scale(25))
        self.ayah_source_edit = QTextEdit()
        self.ayah_source_edit.setFixedHeight(scale(36))
        self.ayah_source_edit.setReadOnly(True)
        self.hadith_quality_edit = QTextEdit()
        self.hadith_quality_edit.setFixedHeight(scale(28))
        self.hadith_quality_edit.setReadOnly(True)
        self.hadith_source_edit = QTextEdit()
        self.hadith_source_edit.setFixedHeight(scale(28))
        self.hadith_source_edit.setReadOnly(True)
        self.ar_edit = QTextEdit()
        self.tr_edit = QTextEdit()
        self.en_edit = QTextEdit()
        self.tr_alt_edit = QTextEdit()
        self.en_alt_edit = QTextEdit()
        self._expanding_text_edits = [
            self.ar_edit,
            self.tr_edit,
            self.en_edit,
            self.tr_alt_edit,
            self.en_alt_edit,
        ]
        for widget in (self.ar_edit, self.tr_edit, self.en_edit):
            widget.setFixedHeight(TEXT_EDITOR_BASE_HEIGHT)
            widget.setSizePolicy(QSizePolicy.Preferred, QSizePolicy.Fixed)
        for widget in (self.tr_alt_edit, self.en_alt_edit):
            widget.setFixedHeight(TEXT_EDITOR_BASE_HEIGHT)
            widget.setSizePolicy(QSizePolicy.Preferred, QSizePolicy.Fixed)

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
        self.ar_font_spin.setValue(15)
        self._bind_font_size(self.ar_font_spin, self.ar_edit, '"Times New Roman", Times, serif')
        self._bind_font_size(self.tr_font_spin, self.tr_edit)
        self._bind_font_size(self.en_font_spin, self.en_edit)
        self._bind_font_size(self.tr_alt_font_spin, self.tr_alt_edit)
        self._bind_font_size(self.en_alt_font_spin, self.en_alt_edit)

        self.ayah_source_row = self._labeled_editor("Ayet kaynak ozeti", self.ayah_source_edit)
        self.hadith_summary_row = QWidget()
        self.hadith_summary_row.setSizePolicy(QSizePolicy.Preferred, QSizePolicy.Fixed)
        hadith_summary_layout = QHBoxLayout(self.hadith_summary_row)
        hadith_summary_layout.setContentsMargins(0, 0, 0, 0)
        hadith_summary_layout.setSpacing(0)
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
        identity_layout.setSpacing(0)
        identity_layout.addWidget(QLabel("Kimlik"))
        identity_layout.addWidget(self.id_label, 1)
        identity_layout.addWidget(QLabel("Referans"))
        identity_layout.addWidget(self.ref_label, 1)
        form.addRow(identity_row)
        form.addRow("Durum", self.status_combo)
        priority_notes_row = QWidget()
        priority_notes_layout = QHBoxLayout(priority_notes_row)
        priority_notes_layout.setContentsMargins(0, 0, 0, 0)
        priority_notes_layout.setSpacing(0)
        priority_notes_layout.addWidget(QLabel("Öncelik"))
        priority_notes_layout.addWidget(self.priority_combo)
        priority_notes_layout.addStretch(1)
        priority_notes_layout.addWidget(QLabel("Not"))
        priority_notes_layout.addWidget(self.notes_edit)
        form.addRow(priority_notes_row)
        form.addRow("Ayet kaynak", self.ayah_source_row)
        form.addRow("Hadis özeti", self.hadith_summary_row)
        text_form.addRow("Arapça metin", self._editor_with_font_row(self.ar_font_spin, self.ar_edit))
        text_form.addRow("Türkçe metin", self.tr_translation_row)
        text_form.addRow("İngilizce metin", self.en_translation_row)
        form_box_layout.addLayout(form)
        form_box_layout.addLayout(text_form, 1)
        layout.addWidget(form_box, 1)

        buttons = QHBoxLayout()
        buttons.setSpacing(0)
        self.save_btn = QPushButton("Taslak olarak kaydet")
        self.save_btn.clicked.connect(self._save_draft)
        self.approve_btn = QPushButton("Onayla ve kaydet")
        self.approve_btn.clicked.connect(self._approve_and_save)
        buttons.addWidget(self.save_btn)
        buttons.addWidget(self.approve_btn)
        layout.addLayout(buttons)
        self._toggle_kind_fields()

    def resizeEvent(self, event) -> None:
        super().resizeEvent(event)
        if self._text_resize_base_height is None:
            self._text_resize_base_height = self.height()
        extra_height = max(0, self.height() - self._text_resize_base_height)
        editor_height = TEXT_EDITOR_BASE_HEIGHT + (extra_height // 3)
        for editor in self._expanding_text_edits:
            editor.setFixedHeight(editor_height)
            editor.updateGeometry()

    def _toggle_kind_fields(self, *_args) -> None:
        self._reset_form_for_kind_change()
        is_hadith = str(self.kind_combo.currentData() or "ayah") == "hadith"
        self.book_ref_tr_edit.setVisible(False)
        self.book_ref_en_edit.setVisible(False)
        self.ayah_source_row.setVisible(not is_hadith)
        self._set_row_visible(self.hadith_summary_row, is_hadith)
        self._configure_translation_mode(is_hadith)
        self._set_translation_alt_visible(not is_hadith)

    def _check_and_fetch(self) -> None:
        kind = str(self.kind_combo.currentData() or "ayah")
        try:
            normalized = normalize_reference(kind, self.reference_edit.text())
        except ValueError as exc:
            quiet_warning(self, "Referans hatası", str(exc))
            return

        ref = str(normalized["ref"])
        archive_record = self.repository.find_archive_record(kind, ref)
        approved_record = self.repository.find_approved_record(kind, ref)
        self._current_archive_record = archive_record
        self._current_approved_record = approved_record
        if kind == "ayah" and isinstance(approved_record, AyahRecord):
            fetch_label = "local_approved"
            source_info = SourceInfo(
                label="approved ayet payload",
                source_ref=self.repository.paths.approved_ayah_path.name,
                fetch_status=fetch_label,
                details={"approvedPath": str(self.repository.paths.approved_ayah_path)},
            )
            record = self._build_approved_ayah_add_record(normalized, approved_record, source_info)
        else:
            fetch_label = "local_archive"
            record = archive_record
            source_info = archive_record.source_info if archive_record else SourceInfo(label="manual", fetch_status="manual")

        if record is None:
            fetch_label = "not_found"
            if kind == "ayah":
                self.fetch_status_label.setText("Veri durumu: Yerel Tanzil havuzunda aranıyor...")
            else:
                self.fetch_status_label.setText("Veri durumu: Yerel hadis havuzunda aranıyor...")
            self.fetch_progress.setVisible(True)
            self.check_btn.setEnabled(False)
            QApplication.processEvents()
            if kind == "ayah":
                result = self.ayah_fetcher.fetch_reference(normalized)
            else:
                result = self.hadith_fetcher.fetch(int(normalized["hadith_number"]))
            source_info = result.source_info
            fetch_label = result.status_label
            record = self._build_new_record(
                kind,
                normalized,
                result.ar,
                result.tr,
                result.en,
                source_info,
                dict(result.extra.get("raw_record") or {}),
            )
            if kind == "hadith":
                record = replace(record, status="fetched" if result.success else "draft")
            else:
                record = replace(record, status="fetched" if result.success else "draft")
            self.fetch_progress.setVisible(False)
            self.check_btn.setEnabled(True)
        else:
            record = replace(record)
            self.fetch_progress.setVisible(False)
            self.check_btn.setEnabled(True)

        duplicate_info = self.repository.build_duplicate_info(record)
        self._current_duplicate = duplicate_info
        self._current_source = source_info
        self._current_record = record
        self.archive_check.setChecked(archive_record is not None)
        self.approved_check.setChecked(approved_record is not None)
        self.exact_check.setChecked(duplicate_info.exact_duplicate)
        self.possible_check.setChecked(duplicate_info.possible_duplicate)
        self.nearby_hadith_check.setChecked(fetch_label == "local_hadith_nearby")
        self.match_warning_label.setText(self._build_match_warning(record, fetch_label))
        self.fetch_status_label.setText(f"Veri durumu: {_fetch_status_label(fetch_label)}")
        self._load_record(record)
        self._sync_availability_ui()

    def _build_approved_ayah_add_record(
        self,
        normalized: dict[str, object],
        approved_record: AyahRecord,
        source_info: SourceInfo,
    ) -> AyahRecord:
        now = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
        raw = dict(approved_record.raw or {})
        raw.update(
            {
                "source": {
                    "arabic": "ayahs.v1.approved.json",
                    "trAlt": "ayahs.v1.approved.json / approved TR",
                    "enAlt": "ayahs.v1.approved.json / approved EN",
                },
                "text_tr_alt": approved_record.tr,
                "text_en_alt": approved_record.en,
                "selected_translation": {"tr": "alt", "en": "alt"},
            }
        )
        return AyahRecord(
            id=str(normalized["id"]),
            kind="ayah",
            ref=str(normalized["ref"]),
            ar=approved_record.ar,
            tr="",
            en="",
            status="fetched",
            priority=approved_record.priority,
            notes="",
            source_info=source_info,
            duplicate_info=DuplicateCheckResult(),
            review_history=[],
            created_at=now,
            updated_at=now,
            approved_at="",
            raw=raw,
            surah_number=int(normalized["surah_number"]),
            ayah_number=int(normalized["ayah_number"]),
            ayah_end_number=int(normalized["ayah_end"]),
            surah_name=str(normalized["surah_name"]),
        )

    def _build_new_record(
        self,
        kind: str,
        normalized: dict[str, object],
        ar: str,
        tr: str,
        en: str,
        source_info: SourceInfo,
        raw_record: dict[str, object] | None = None,
    ) -> BaseRecord:
        now = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
        if kind == "ayah":
            return AyahRecord(
                id=str(normalized["id"]),
                kind="ayah",
                ref=str(normalized["ref"]),
                ar=ar,
                tr=tr,
                en=en,
                status="draft",
                priority=1,
                notes="",
                source_info=source_info,
                duplicate_info=DuplicateCheckResult(),
                review_history=[],
                created_at=now,
                updated_at=now,
                approved_at="",
                surah_number=int(normalized["surah_number"]),
                ayah_number=int(normalized["ayah_number"]),
                surah_name=str(normalized["surah_name"]),
                raw=dict(raw_record or {}),
            )
        return HadithRecord(
            id=str(normalized["id"]),
            kind="hadith",
            ref=str(normalized["ref"]),
            ar=ar,
            tr=tr,
            en=en,
            status="draft",
            priority=1,
            notes="",
            source_info=source_info,
            duplicate_info=DuplicateCheckResult(),
            review_history=[],
            created_at=now,
            updated_at=now,
            approved_at="",
            hadith_number=int(normalized["hadith_number"]),
            raw=dict(raw_record or {}),
        )

    def _load_record(self, record: BaseRecord) -> None:
        self.id_label.setText(record.id)
        self.ref_label.setText(record.ref)
        self.status_combo.setCurrentIndex(max(0, self.status_combo.findData(record.status)))
        self.priority_combo.setCurrentIndex(max(0, self.priority_combo.findData(self._normalize_priority(record.priority))))
        self.notes_edit.setPlainText(record.notes)
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
        else:
            self.book_ref_tr_edit.setPlainText("")
            self.book_ref_en_edit.setPlainText("")
            self.ayah_source_edit.setPlainText(self._extract_ayah_source_summary(record))
            tr_alt_text = self._extract_ayah_alt_text(record, "tr")
            en_alt_text = self._extract_ayah_alt_text(record, "en")
            self.tr_alt_edit.setPlainText(tr_alt_text)
            self.en_alt_edit.setPlainText(en_alt_text)
            self._restore_translation_selection(record, "tr", tr_alt_text)
            self._restore_translation_selection(record, "en", en_alt_text)
            self.hadith_quality_edit.setPlainText("")
            self.hadith_source_edit.setPlainText("")

    def _save_draft(self) -> None:
        self._save("draft")

    def _approve_and_save(self) -> None:
        self._save("approved")

    def _replace_approved_and_save(self) -> None:
        if self._current_approved_record is None:
            quiet_information(self, "Yayinda kayit yok", "Degistirilecek yayin kaydi bulunamadi.")
            return
        if not quiet_confirm(
            self,
            "Yayindaki kaydi degistir",
            "Yayindaki mevcut kayit, ekrandaki yeni metinlerle guncellenecek. Devam edilsin mi?",
        ):
            return
        self._save("approved", replace_existing_approved=True)

    def _save(self, forced_status: str, replace_existing_approved: bool = False) -> None:
        if self._current_record is None:
            quiet_information(self, "Kayıt yok", "Önce referans kontrolü yapin.")
            return
        record = replace(
            self._current_record,
            status=forced_status if forced_status else str(self.status_combo.currentData() or "draft"),
            priority=int(self.priority_combo.currentData() or 1),
            notes=self.notes_edit.toPlainText().strip(),
            ar=self.ar_edit.toPlainText().strip(),
            tr=self._selected_translation_text("tr"),
            en=self._selected_translation_text("en"),
            source_info=self._current_source,
            duplicate_info=self._current_duplicate,
        )
        if isinstance(record, AyahRecord):
            raw = dict(record.raw or {})
            raw["text_tr_alt"] = self.tr_alt_edit.toPlainText().strip()
            raw["text_en_alt"] = self.en_alt_edit.toPlainText().strip()
            raw["selected_translation"] = {
                "tr": "alt" if self.tr_alt_check.isChecked() else "main",
                "en": "alt" if self.en_alt_check.isChecked() else "main",
            }
            record = replace(record, raw=raw)
        if isinstance(record, HadithRecord):
            record = replace(
                record,
                book_reference_tr=self.book_ref_tr_edit.toPlainText().strip(),
                book_reference_en=self.book_ref_en_edit.toPlainText().strip(),
            )
        if record.status == "approved" and self._current_approved_record is not None:
            if not replace_existing_approved:
                quiet_warning(
                    self,
                    "Yayinda mevcut",
                    "Bu referans yayindaki onayli kayitlarda var. Yeni ekleme kapatildi; guncellemek icin Degistir'i kullanin.",
                )
                self._sync_availability_ui()
                return
            record = replace(
                record,
                id=self._current_approved_record.id,
                ref=self._current_approved_record.ref,
            )
        if record.status == "approved":
            record = replace(
                record,
                approved_at=datetime.now(timezone.utc).replace(microsecond=0).isoformat(),
            )
        try:
            saved = self.repository.save_record(record)
        except StorageConflictError as exc:
            quiet_critical(self, "Hash catismasi", str(exc))
            return
        except Exception as exc:
            quiet_critical(self, "Kaydetme hatası", str(exc))
            return
        if not self._sync_publish_files():
            return
        self._current_record = saved
        self._current_archive_record = saved
        if saved.status == "approved":
            self._current_approved_record = saved
            quiet_information(self, "Yayin", "Yayinlanacaklara eklendi.")
        self._load_record(saved)
        self.archive_check.setChecked(True)
        if saved.status == "approved":
            self.approved_check.setChecked(True)
        self.fetch_status_label.setText("Veri durumu: Kayıt başarıyla yazildi")
        self._sync_availability_ui()

    def _undo_last(self) -> None:
        if not self.repository.undo_last_write():
            quiet_information(self, "Undo", "Geri alinacak yazım yok.")
            return
        if not self._sync_publish_files():
            return
        quiet_information(self, "Undo", "Son yazım geri alındı.")

    def _sync_publish_files(self) -> bool:
        try:
            sync_approved_publish(self.repository.paths.repo_root)
        except Exception as exc:
            quiet_critical(self, "Publish sync hatası", str(exc))
            return False
        return True

    def _build_font_spin(self) -> QSpinBox:
        spin = QSpinBox()
        spin.setRange(13, 36)
        spin.setValue(13)
        spin.setSuffix(" pt")
        spin.setMaximumWidth(scale(90))
        return spin

    def _bind_font_size(self, spin: QSpinBox, editor: QTextEdit, font_family: str = "") -> None:
        def apply_font(value: int) -> None:
            style_parts = [f"font-size: {value}pt"]
            if font_family:
                style_parts.append(f"font-family: {font_family}")
            editor.setStyleSheet("; ".join(style_parts) + ";")

        spin.valueChanged.connect(apply_font)
        apply_font(spin.value())

    def _editor_with_font_row(self, spin: QSpinBox, editor: QTextEdit) -> QWidget:
        panel = QWidget()
        panel.setSizePolicy(QSizePolicy.Preferred, QSizePolicy.Fixed)
        panel_layout = QVBoxLayout(panel)
        panel_layout.setContentsMargins(0, 0, 0, 0)
        panel_layout.setSpacing(0)
        top = QHBoxLayout()
        top.setContentsMargins(0, 0, 0, 0)
        top.setSpacing(0)
        top.addWidget(QLabel("Yazi boyutu"))
        top.addWidget(spin)
        top.addStretch(1)
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
        row.setSizePolicy(QSizePolicy.Preferred, QSizePolicy.Fixed)
        row_layout = QHBoxLayout(row)
        row_layout.setContentsMargins(0, 0, 0, 0)
        row_layout.setSpacing(0)
        left_panel = self._choice_editor_panel(left_title, left_check, left_spin, left_editor)
        right_panel = self._choice_editor_panel(right_title, right_check, right_spin, right_editor)
        row.left_panel = left_panel
        row.right_panel = right_panel
        row_layout.addWidget(left_panel)
        row_layout.addWidget(right_panel)
        return row

    def _choice_editor_panel(self, title: str, check: QCheckBox, spin: QSpinBox, editor: QTextEdit) -> QWidget:
        panel = QWidget()
        panel.setSizePolicy(QSizePolicy.Preferred, QSizePolicy.Fixed)
        panel.setStyleSheet("background:#fafafa; border:1px solid #d8d8d8; border-radius:8px;")
        panel_layout = QVBoxLayout(panel)
        panel_layout.setContentsMargins(0, 0, 0, 0)
        panel_layout.setSpacing(0)
        title_row = QHBoxLayout()
        title_row.setContentsMargins(0, 0, 0, 0)
        title_row.setSpacing(0)
        label = QLabel(title)
        label.setStyleSheet(f"font-size: {pt(14)}pt; font-weight: 600;")
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
        panel.setSizePolicy(QSizePolicy.Preferred, QSizePolicy.Fixed)
        panel.setStyleSheet("background:#fafafa; border:1px solid #d8d8d8; border-radius:8px;")
        panel_layout = QVBoxLayout(panel)
        panel_layout.setContentsMargins(0, 0, 0, 0)
        panel_layout.setSpacing(0)
        title = QLabel(label)
        title.setStyleSheet(f"font-size: {pt(14)}pt; font-weight: 600;")
        panel_layout.addWidget(title)
        panel_layout.addWidget(editor)
        return panel

    def _build_status_check(self, label: str) -> QCheckBox:
        check = QCheckBox(label)
        check.setEnabled(False)
        check.setStyleSheet(f"font-size: {pt(14)}pt; font-weight: 600;")
        return check

    def _set_presence_label(self, label: QLabel, title: str, exists: bool) -> None:
        text = "VAR" if exists else "YOK"
        color = "#7a1f1f" if exists and title == "Yayin" else "#1f5d35" if exists else "#555555"
        label.setText(f"{title}: {text}")
        label.setStyleSheet(
            "background:#f7f7f7; border:1px solid #d6d6d6; border-radius:5px; "
            f"padding:2px 8px; font-weight:700; color:{color};"
        )

    def _sync_availability_ui(self) -> None:
        approved_exists = self._current_approved_record is not None
        archive_exists = self._current_archive_record is not None
        if hasattr(self, "archive_state_label"):
            self._set_presence_label(self.archive_state_label, "Arsiv", archive_exists)
        if hasattr(self, "approved_state_label"):
            self._set_presence_label(self.approved_state_label, "Yayin", approved_exists)
        if hasattr(self, "approve_btn"):
            self.approve_btn.setEnabled(self._current_record is not None and not approved_exists)
        elif hasattr(self, "save_btn"):
            self.save_btn.setEnabled(self._current_record is not None and not approved_exists)
        if hasattr(self, "replace_btn"):
            self.replace_btn.setEnabled(self._current_record is not None and approved_exists)

    def _build_translation_check(self, label: str) -> QCheckBox:
        check = QCheckBox(label)
        check.setStyleSheet(f"font-size: {pt(14)}pt; font-weight: 600;")
        return check

    def _normalize_priority(self, value: int) -> int:
        try:
            priority = int(value)
        except (TypeError, ValueError):
            return 1
        return max(1, min(3, priority))

    def _set_row_visible(self, widget: QWidget, visible: bool) -> None:
        widget.setVisible(visible)

    def _reset_form_for_kind_change(self) -> None:
        self._current_record = None
        self._current_archive_record = None
        self._current_approved_record = None
        self._current_duplicate = DuplicateCheckResult()
        self._current_source = SourceInfo()
        self.reference_edit.clear()
        self.id_label.setText("-")
        self.ref_label.setText("-")
        self.status_combo.setCurrentIndex(max(0, self.status_combo.findData("draft")))
        self.priority_combo.setCurrentIndex(0)
        self.notes_edit.clear()
        self.ar_edit.clear()
        self.tr_edit.clear()
        self.en_edit.clear()
        self.tr_alt_edit.clear()
        self.en_alt_edit.clear()
        self.book_ref_tr_edit.clear()
        self.book_ref_en_edit.clear()
        self.ayah_source_edit.clear()
        self.hadith_quality_edit.clear()
        self.hadith_source_edit.clear()
        self.archive_check.setChecked(False)
        self.approved_check.setChecked(False)
        self.exact_check.setChecked(False)
        self.possible_check.setChecked(False)
        self.nearby_hadith_check.setChecked(False)
        self.match_warning_label.setText("")
        self.fetch_status_label.setText("Veri durumu: henüz kontrol edilmedi")
        self.fetch_progress.setVisible(False)
        self.check_btn.setEnabled(True)
        self._sync_availability_ui()

    def _set_translation_alt_visible(self, visible: bool) -> None:
        self.tr_translation_row.right_panel.setVisible(visible)
        self.en_translation_row.right_panel.setVisible(visible)
        if not visible:
            self.tr_main_check.setChecked(True)
            self.en_main_check.setChecked(True)
            self.tr_alt_edit.setPlainText("")
            self.en_alt_edit.setPlainText("")

    def _configure_translation_mode(self, is_hadith: bool) -> None:
        self.tr_main_check.setVisible(not is_hadith)
        self.en_main_check.setVisible(not is_hadith)
        self.tr_alt_check.setVisible(not is_hadith)
        self.en_alt_check.setVisible(not is_hadith)
        if is_hadith:
            self.tr_translation_row.left_panel.title_label.setText("Hadis Türkçe metni")
            self.en_translation_row.left_panel.title_label.setText("Hadis İngilizce metni")
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
        if str(self.kind_combo.currentData() or "ayah") == "hadith":
            return self.tr_edit.toPlainText().strip() if language == "tr" else self.en_edit.toPlainText().strip()
        if language == "tr":
            return self.tr_alt_edit.toPlainText().strip() if self.tr_alt_check.isChecked() else self.tr_edit.toPlainText().strip()
        return self.en_alt_edit.toPlainText().strip() if self.en_alt_check.isChecked() else self.en_edit.toPlainText().strip()

    def _build_match_warning(self, record: BaseRecord, fetch_label: str) -> str:
        if not isinstance(record, HadithRecord):
            return ""
        if fetch_label == "local_hadith_nearby":
            return "Uyarı: Bu kayıt yakın hadis numarasından geldi. Onaydan önce metin eşleşmesini kontrol et."
        quality = record.raw.get("quality") if isinstance(record.raw, dict) else None
        if isinstance(quality, dict):
            confidence = str(quality.get("matchConfidence") or "").lower()
            match_status = str(quality.get("matchStatus") or "").lower()
            if confidence in {"low", "medium"} or "manual" in match_status or "light" in match_status:
                return "Uyarı: Hadis eşleşmesi kesin olmayabilir. Kaynak ve metin uyumunu kontrol et."
        return ""

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
                if language == "tr":
                    alt = alternatives.get("tr_diyanet_tanzil")
                else:
                    alt = alternatives.get("en_maududi")
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
            f"Bolum: {chapter.get('title_tr') or chapter.get('diyanet_tr') or chapter.get('sunnah') or '-'}",
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



