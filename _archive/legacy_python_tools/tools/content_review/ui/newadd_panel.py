from __future__ import annotations

from dataclasses import replace
from datetime import datetime, timezone

from PySide6.QtWidgets import (
    QComboBox,
    QFormLayout,
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

from core.fetchers.ayah_fetcher import AyahFetcher
from core.fetchers.hadith_fetcher import HadithFetcher
from core.models import (
    AyahRecord,
    BaseRecord,
    DuplicateCheckResult,
    HadithRecord,
    SourceInfo,
)
from core.publish_sync import sync_approved_publish
from core.reference_parser import normalize_reference
from core.storage import ContentRepository, StorageConflictError
from ui.scale import scale


STATUS_LABELS = {
    "draft": "Taslak",
    "fetched": "Getirildi",
    "needs_review": "İnceleme gerekli",
    "needs_translation": "Çeviri gerekli",
    "needs_source_check": "Kaynak kontrolü gerekli",
    "approved": "Onaylı",
}

FETCH_LABELS = {
    "manual": "Manuel giriş",
    "local_archive": "Arşiv kaydı bulundu",
    "local_approved": "Yayın kaydı bulundu",
    "local_tanzil_exact": "Yerel ayet kaynağından getirildi",
    "local_tanzil_missing": "Yerel ayet kaynağında bulunamadı",
    "local_source_missing": "Yerel kaynak dosyası bulunamadı",
    "local_hadith_exact": "Yerel hadis kaynağından getirildi",
    "local_hadith_nearby": "Yakın hadis adayı bulundu",
    "local_hadith_missing": "Yerel hadis kaynağında bulunamadı",
    "local_hadith_source_missing": "Yerel hadis kaynak dosyası bulunamadı",
    "fetch_error": "Getirme sırasında hata oluştu",
    "saved": "Kayıt başarıyla yazıldı",
}


class NewAddPanel(QWidget):
    def __init__(self, repository: ContentRepository) -> None:
        super().__init__()
        self.repository = repository
        self.ayah_fetcher = AyahFetcher()
        self.hadith_fetcher = HadithFetcher()
        self._current_record: BaseRecord | None = None
        self._current_archive_record: BaseRecord | None = None
        self._current_approved_record: BaseRecord | None = None
        self._current_source = SourceInfo(label="manual", fetch_status="manual")
        self._current_duplicate = DuplicateCheckResult()
        self._build_ui()
        self._sync_kind_fields()
        self._reset_status()

    def _build_ui(self) -> None:
        root = QVBoxLayout(self)
        root.setContentsMargins(scale(12), scale(12), scale(12), scale(12))
        root.setSpacing(scale(10))

        top_box = QGroupBox("Yeni içerik ekle")
        top_layout = QHBoxLayout(top_box)
        self.kind_combo = QComboBox()
        self.kind_combo.addItem("Ayet", "ayah")
        self.kind_combo.addItem("Hadis", "hadith")
        self.kind_combo.currentIndexChanged.connect(self._sync_kind_fields)
        self.reference_edit = QLineEdit()
        self.reference_edit.setPlaceholderText("Ayet: 002/255 veya 018/001-010 | Hadis: 706")
        self.fetch_btn = QPushButton("Kontrol / Getir")
        self.fetch_btn.clicked.connect(self._check_and_fetch)
        self.clear_btn = QPushButton("Temizle")
        self.clear_btn.clicked.connect(self._clear_form)
        self.undo_btn = QPushButton("Son yazımı geri al")
        self.undo_btn.clicked.connect(self._undo_last)
        top_layout.addWidget(QLabel("Tür"))
        top_layout.addWidget(self.kind_combo)
        top_layout.addWidget(QLabel("Referans"))
        top_layout.addWidget(self.reference_edit, 1)
        top_layout.addWidget(self.fetch_btn)
        top_layout.addWidget(self.clear_btn)
        top_layout.addWidget(self.undo_btn)
        root.addWidget(top_box)

        status_box = QGroupBox("Durum")
        status_layout = QVBoxLayout(status_box)
        self.fetch_status_label = QLabel("Veri durumu: -")
        self.fetch_status_label.setWordWrap(True)
        self.archive_label = QLabel("Arşiv: -")
        self.approved_label = QLabel("Yayın: -")
        self.duplicate_label = QLabel("Benzerlik: -")
        status_row = QHBoxLayout()
        status_row.addWidget(self.archive_label)
        status_row.addWidget(self.approved_label)
        status_row.addWidget(self.duplicate_label, 1)
        status_layout.addWidget(self.fetch_status_label)
        status_layout.addLayout(status_row)
        root.addWidget(status_box)

        meta_box = QGroupBox("Kimlik ve yayın bilgisi")
        meta_form = QFormLayout(meta_box)
        self.id_edit = QLineEdit()
        self.ref_edit = QLineEdit()
        self.status_combo = QComboBox()
        for value, label in STATUS_LABELS.items():
            self.status_combo.addItem(label, value)
        self.priority_spin = QSpinBox()
        self.priority_spin.setRange(1, 3)
        self.priority_spin.setValue(1)
        self.notes_edit = QLineEdit()
        self.book_ref_tr_edit = QLineEdit()
        self.book_ref_en_edit = QLineEdit()
        self.source_label_edit = QLineEdit()
        self.source_ref_edit = QLineEdit()
        meta_form.addRow("ID", self.id_edit)
        meta_form.addRow("Ref", self.ref_edit)
        meta_form.addRow("Durum", self.status_combo)
        meta_form.addRow("Öncelik", self.priority_spin)
        meta_form.addRow("Not", self.notes_edit)
        meta_form.addRow("TR kaynak", self.book_ref_tr_edit)
        meta_form.addRow("EN kaynak", self.book_ref_en_edit)
        meta_form.addRow("Kaynak etiketi", self.source_label_edit)
        meta_form.addRow("Kaynak ref", self.source_ref_edit)
        root.addWidget(meta_box)

        text_box = QGroupBox("Metinler")
        text_layout = QFormLayout(text_box)
        self.ar_edit = self._text_editor("Arapça metin")
        self.tr_edit = self._text_editor("Türkçe metin")
        self.en_edit = self._text_editor("İngilizce metin")
        text_layout.addRow("Arapça", self.ar_edit)
        text_layout.addRow("Türkçe", self.tr_edit)
        text_layout.addRow("İngilizce", self.en_edit)
        root.addWidget(text_box, 1)

        button_row = QHBoxLayout()
        self.save_draft_btn = QPushButton("Taslak olarak kaydet")
        self.save_draft_btn.clicked.connect(lambda: self._save("draft"))
        self.approve_btn = QPushButton("Onayla ve yayına yaz")
        self.approve_btn.clicked.connect(lambda: self._save("approved"))
        button_row.addStretch(1)
        button_row.addWidget(self.save_draft_btn)
        button_row.addWidget(self.approve_btn)
        root.addLayout(button_row)

    def _text_editor(self, placeholder: str) -> QTextEdit:
        editor = QTextEdit()
        editor.setPlaceholderText(placeholder)
        editor.setAcceptRichText(False)
        editor.setMinimumHeight(scale(110))
        return editor

    def _sync_kind_fields(self, *_args: object) -> None:
        if hasattr(self, "book_ref_tr_edit"):
            self.book_ref_tr_edit.setPlaceholderText("Hadis için kitap/kaynak bilgisi; ayet için boş bırakılabilir")
            self.book_ref_en_edit.setPlaceholderText("Hadis için English source; ayet için boş bırakılabilir")
        self._clear_form(keep_reference=True)

    def _kind(self) -> str:
        return str(self.kind_combo.currentData() or "ayah")

    def _clear_form(self, keep_reference: bool = False) -> None:
        reference = self.reference_edit.text() if keep_reference else ""
        self._current_record = None
        self._current_archive_record = None
        self._current_approved_record = None
        self._current_source = SourceInfo(label="manual", fetch_status="manual")
        self._current_duplicate = DuplicateCheckResult()
        self.id_edit.clear()
        self.ref_edit.clear()
        self.priority_spin.setValue(1)
        self.notes_edit.clear()
        self.book_ref_tr_edit.clear()
        self.book_ref_en_edit.clear()
        self.source_label_edit.clear()
        self.source_ref_edit.clear()
        self.ar_edit.clear()
        self.tr_edit.clear()
        self.en_edit.clear()
        self.reference_edit.setText(reference)
        self._reset_status()

    def _reset_status(self) -> None:
        self.status_combo.setCurrentIndex(max(0, self.status_combo.findData("fetched")))
        self.fetch_status_label.setText("Veri durumu: -")
        self.archive_label.setText("Arşiv: -")
        self.approved_label.setText("Yayın: -")
        self.duplicate_label.setText("Benzerlik: -")

    def _check_and_fetch(self) -> None:
        try:
            normalized = normalize_reference(self._kind(), self.reference_edit.text())
        except ValueError as exc:
            self._warning("Referans hatası", str(exc))
            return

        ref = str(normalized["ref"])
        archive_record = self.repository.find_archive_record(self._kind(), ref)
        approved_record = self.repository.find_approved_record(self._kind(), ref)
        self._current_archive_record = archive_record
        self._current_approved_record = approved_record

        if archive_record is not None:
            record = replace(archive_record)
            source = archive_record.source_info
            fetch_status = "local_archive"
        elif approved_record is not None:
            record = replace(approved_record)
            source = SourceInfo(
                label="approved payload",
                source_ref=self._approved_source_name(self._kind()),
                fetch_status="local_approved",
            )
            fetch_status = "local_approved"
        else:
            record, source, fetch_status = self._fetch_new_record(normalized)

        duplicate = self.repository.build_duplicate_info(record)
        self._current_record = replace(record, duplicate_info=duplicate, source_info=source)
        self._current_source = source
        self._current_duplicate = duplicate
        self._load_record(self._current_record)
        self._show_status(fetch_status)

    def _fetch_new_record(self, normalized: dict[str, object]) -> tuple[BaseRecord, SourceInfo, str]:
        kind = self._kind()
        try:
            if kind == "ayah":
                result = self.ayah_fetcher.fetch_reference(normalized)
            else:
                result = self.hadith_fetcher.fetch(int(normalized["hadith_number"]))
        except Exception as exc:
            source = SourceInfo(label="manual", fetch_status="fetch_error", details={"error": str(exc)})
            return self._build_empty_record(normalized, source), source, "fetch_error"

        record = self._build_record(
            normalized=normalized,
            ar=result.ar,
            tr=result.tr,
            en=result.en,
            source=result.source_info,
            raw=dict(result.extra.get("raw_record") or {}),
        )
        status = "fetched" if result.success else "needs_source_check"
        record = replace(record, status=status)
        return record, result.source_info, result.status_label

    def _build_empty_record(self, normalized: dict[str, object], source: SourceInfo) -> BaseRecord:
        return self._build_record(normalized=normalized, ar="", tr="", en="", source=source, raw={})

    def _build_record(
        self,
        normalized: dict[str, object],
        ar: str,
        tr: str,
        en: str,
        source: SourceInfo,
        raw: dict[str, object],
    ) -> BaseRecord:
        now = self._utc_now()
        if self._kind() == "ayah":
            return AyahRecord(
                id=str(normalized["id"]),
                kind="ayah",
                ref=str(normalized["ref"]),
                ar=ar,
                tr=tr,
                en=en,
                status="fetched",
                priority=1,
                notes="",
                source_info=source,
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
        return HadithRecord(
            id=str(normalized["id"]),
            kind="hadith",
            ref=str(normalized["ref"]),
            ar=ar,
            tr=tr,
            en=en,
            status="fetched",
            priority=1,
            notes="",
            source_info=source,
            duplicate_info=DuplicateCheckResult(),
            review_history=[],
            created_at=now,
            updated_at=now,
            approved_at="",
            raw=raw,
            hadith_number=int(normalized["hadith_number"]),
        )

    def _load_record(self, record: BaseRecord) -> None:
        self.id_edit.setText(record.id)
        self.ref_edit.setText(record.ref)
        self.status_combo.setCurrentIndex(max(0, self.status_combo.findData(record.status)))
        self.priority_spin.setValue(max(1, min(3, int(record.priority or 1))))
        self.notes_edit.setText(record.notes)
        self.source_label_edit.setText(record.source_info.label)
        self.source_ref_edit.setText(record.source_info.source_ref)
        self.ar_edit.setPlainText(record.ar)
        self.tr_edit.setPlainText(record.tr)
        self.en_edit.setPlainText(record.en)
        if isinstance(record, HadithRecord):
            self.book_ref_tr_edit.setText(record.book_reference_tr)
            self.book_ref_en_edit.setText(record.book_reference_en)
        else:
            self.book_ref_tr_edit.clear()
            self.book_ref_en_edit.clear()

    def _save(self, forced_status: str) -> None:
        try:
            record = self._record_from_form(forced_status)
        except ValueError as exc:
            self._warning("Kayıt hatası", str(exc))
            return

        if forced_status == "approved" and self._current_approved_record is not None:
            if not self._confirm(
                "Yayındaki kayıt güncellensin mi?",
                "Bu referans yayında zaten var. Devam edersen mevcut yayın kaydı ekrandaki metinlerle güncellenir.",
            ):
                return
            record = replace(record, id=self._current_approved_record.id, ref=self._current_approved_record.ref)

        if forced_status == "approved":
            record = replace(record, status="approved", approved_at=self._utc_now())
        elif forced_status == "draft":
            record = replace(record, status="draft")

        try:
            saved = self.repository.save_record(record)
            sync_approved_publish(self.repository.paths.repo_root)
        except StorageConflictError as exc:
            self._critical("Hash çakışması", str(exc))
            return
        except Exception as exc:
            self._critical("Kaydetme hatası", str(exc))
            return

        self.repository.reload()
        self._current_record = saved
        self._current_archive_record = saved
        self._current_approved_record = self.repository.find_approved_record(saved.kind, saved.ref)
        self._load_record(saved)
        self._show_status("saved")
        self._info("Kayıt tamam", "JSON dosyalarına başarıyla yazıldı.")

    def _record_from_form(self, forced_status: str) -> BaseRecord:
        kind = self._kind()
        id_value = self.id_edit.text().strip()
        ref_value = self.ref_edit.text().strip()
        if not id_value or not ref_value:
            normalized = normalize_reference(kind, self.reference_edit.text())
            id_value = id_value or str(normalized["id"])
            ref_value = ref_value or str(normalized["ref"])
        source = SourceInfo(
            label=self.source_label_edit.text().strip() or "manual",
            source_ref=self.source_ref_edit.text().strip(),
            fetch_status=self._current_source.fetch_status or "manual",
            details=dict(self._current_source.details or {}),
        )
        base = self._current_record or self._build_empty_record(normalize_reference(kind, ref_value), source)
        record = replace(
            base,
            id=id_value,
            ref=ref_value,
            ar=self.ar_edit.toPlainText().strip(),
            tr=self.tr_edit.toPlainText().strip(),
            en=self.en_edit.toPlainText().strip(),
            status=str(self.status_combo.currentData() or forced_status),
            priority=int(self.priority_spin.value()),
            notes=self.notes_edit.text().strip(),
            source_info=source,
        )
        record = replace(record, duplicate_info=self.repository.build_duplicate_info(record))
        if isinstance(record, HadithRecord):
            record = replace(
                record,
                book_reference_tr=self.book_ref_tr_edit.text().strip(),
                book_reference_en=self.book_ref_en_edit.text().strip(),
            )
        return record

    def _show_status(self, fetch_status: str) -> None:
        duplicate = self._current_duplicate
        archive_exists = self._current_archive_record is not None
        approved_exists = self._current_approved_record is not None
        exact = duplicate.exact_duplicate
        possible = duplicate.possible_duplicate
        self.archive_label.setText(f"Arşiv: {'VAR' if archive_exists else 'YOK'}")
        self.approved_label.setText(f"Yayın: {'VAR' if approved_exists else 'YOK'}")
        self.duplicate_label.setText(f"Benzerlik: exact={exact} possible={possible}")
        self.fetch_status_label.setText(f"Veri durumu: {FETCH_LABELS.get(fetch_status, fetch_status)}")

    def _undo_last(self) -> None:
        if not self.repository.undo_last_write():
            self._info("Geri alma", "Geri alınacak yazım bulunamadı.")
            return
        try:
            sync_approved_publish(self.repository.paths.repo_root)
        except Exception as exc:
            self._critical("Publish sync hatası", str(exc))
            return
        self.repository.reload()
        self._clear_form()
        self._info("Geri alma", "Son yazım geri alındı.")

    def _approved_source_name(self, kind: str) -> str:
        if kind == "ayah":
            return self.repository.paths.approved_ayah_path.name
        return self.repository.paths.approved_hadith_path.name

    @staticmethod
    def _utc_now() -> str:
        return datetime.now(timezone.utc).replace(microsecond=0).isoformat()

    def _warning(self, title: str, message: str) -> None:
        QMessageBox.warning(self, title, message)

    def _critical(self, title: str, message: str) -> None:
        QMessageBox.critical(self, title, message)

    def _info(self, title: str, message: str) -> None:
        QMessageBox.information(self, title, message)

    def _confirm(self, title: str, message: str) -> bool:
        return QMessageBox.question(self, title, message, QMessageBox.Yes | QMessageBox.No) == QMessageBox.Yes
