from __future__ import annotations

import html

from PySide6.QtCore import Qt
from PySide6.QtGui import QTextDocument
from PySide6.QtWidgets import (
    QFrame,
    QHBoxLayout,
    QLabel,
    QLineEdit,
    QPushButton,
    QScrollArea,
    QSizePolicy,
    QVBoxLayout,
    QWidget,
)

from core.approved_preview import ApprovedContentNavigator, MISSING_TEXT, MobilePreviewItem
from core.storage import ContentRepository
from ui.scale import pt, scale


ARABIC_TITLE_FONT_FAMILY = (
    "'ReemKufiFun', 'Reem Kufi Fun', 'Noto Kufi Arabic', "
    "'Traditional Arabic', 'Times New Roman', serif"
)
ARABIC_BODY_FONT_FAMILY = (
    "'Mirza', 'Lateef', 'NotoNaskhArabic', 'Noto Naskh Arabic', "
    "'Amiri', 'Droid Arabic Naskh', 'Geeza Pro', 'Times New Roman', serif"
)


class MobilePreviewCard(QFrame):
    def __init__(self, font_boost: int = 0) -> None:
        super().__init__()
        self._font_boost = font_boost
        self.setObjectName("mobilePreviewCard")
        self.setStyleSheet(
            "#mobilePreviewCard {"
            "background: #1F7A3E;"
            "border: 1px solid rgba(255, 255, 255, 0.12);"
            "border-radius: 10px;"
            "}"
        )

        layout = QVBoxLayout(self)
        layout.setContentsMargins(scale(10), scale(8), scale(10), scale(8))
        layout.setSpacing(0)

        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setFrameShape(QFrame.NoFrame)
        scroll.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        scroll.setStyleSheet("background: transparent;")

        content = QWidget()
        self._content_layout = QVBoxLayout(content)
        self._content_layout.setContentsMargins(0, 0, 0, 0)
        self._content_layout.setSpacing(scale(8))

        self.arabic_title_section, self.arabic_title_label = self._build_section()
        self.arabic_section, self.arabic_label = self._build_section()
        self.arabic_divider = self._build_divider()
        self.turkish_section, self.turkish_label = self._build_section()
        self.turkish_divider = self._build_divider()
        self.english_section, self.english_label = self._build_section()
        self.footer_section = QWidget()
        footer_layout = QVBoxLayout(self.footer_section)
        footer_layout.setContentsMargins(0, scale(2), 0, 0)
        footer_layout.setSpacing(scale(4))
        self.reference_label = self._build_text_label()
        self.source_label = self._build_text_label()
        footer_layout.addWidget(self.reference_label)
        footer_layout.addWidget(self.source_label)

        self._content_layout.addWidget(self.arabic_title_section)
        self._content_layout.addWidget(self.arabic_section)
        self._content_layout.addWidget(self.arabic_divider)
        self._content_layout.addWidget(self.turkish_section)
        self._content_layout.addWidget(self.turkish_divider)
        self._content_layout.addWidget(self.english_section)
        self._content_layout.addWidget(self.footer_section)
        self._content_layout.addStretch(1)

        scroll.setWidget(content)
        layout.addWidget(scroll)

    def set_item(
        self,
        item: MobilePreviewItem | None,
        *,
        show_arabic: bool,
        show_turkish: bool,
        show_english: bool,
        empty_message: str,
    ) -> None:
        if item is None:
            self.arabic_title_section.setVisible(False)
            self.arabic_section.setVisible(True)
            self.arabic_divider.setVisible(False)
            self.turkish_section.setVisible(False)
            self.turkish_divider.setVisible(False)
            self.english_section.setVisible(False)
            self.footer_section.setVisible(True)
            self.source_label.setVisible(True)
            self.arabic_label.setText(
                self._format_html(empty_message, font_size=self._text_pt(18), color="#FFFFFF", italic=True)
            )
            self.reference_label.setText(
                self._format_html(MISSING_TEXT, font_size=self._text_pt(17), color="#F9A825", weight=600)
            )
            self.source_label.setText(
                self._format_html(MISSING_TEXT, font_size=self._text_pt(15), color="#FFFFFF", italic=True, weight=500)
            )
            self._sync_label_heights()
            return

        show_title = bool(item.arabic_title_text.strip()) and (item.kind == "esma" or show_arabic)
        show_arabic_section = show_arabic and bool(item.arabic_text.strip())
        show_turkish_section = show_turkish and bool(item.turkish_text.strip())
        show_english_section = show_english and bool(item.english_text.strip())

        self.arabic_title_section.setVisible(show_title)
        self.arabic_section.setVisible(show_arabic_section)
        self.turkish_section.setVisible(show_turkish_section)
        self.english_section.setVisible(show_english_section)
        self.footer_section.setVisible(item.kind != "esma")
        self.arabic_divider.setVisible(show_arabic_section and (show_turkish_section or show_english_section))
        self.turkish_divider.setVisible(show_turkish_section and show_english_section)

        title_size = 32 if item.kind == "esma" else 24
        title_weight = 500 if item.kind == "esma" else 700
        title_font_family = ARABIC_TITLE_FONT_FAMILY if item.kind == "esma" else ARABIC_BODY_FONT_FAMILY
        self.arabic_title_label.setText(
            self._format_html(
                item.arabic_title_text,
                font_size=self._text_pt(title_size),
                color="#FFFFFF",
                line_height=1.22,
                direction="rtl",
                weight=title_weight,
                font_family=title_font_family,
            )
        )
        arabic_body_size = 21 if item.kind == "esma" else 19
        self.arabic_label.setText(
            self._format_html(
                item.arabic_text,
                font_size=self._text_pt(arabic_body_size),
                color="#FFFFFF",
                line_height=1.28,
                direction="rtl",
                font_family=ARABIC_BODY_FONT_FAMILY,
            )
        )
        self.turkish_label.setText(
            self._format_html(
                item.turkish_text,
                font_size=self._text_pt(17),
                color="#EAF4EC",
                italic=True,
                line_height=1.18,
            )
        )
        self.english_label.setText(
            self._format_html(
                item.english_text,
                font_size=self._text_pt(17),
                color="#EAF4EC",
                line_height=1.18,
            )
        )
        if item.kind != "esma":
            self.reference_label.setText(
                self._format_html(item.reference_text, font_size=self._text_pt(17), color="#F9A825", weight=600)
            )
            self.source_label.setVisible(item.source_text != MISSING_TEXT)
            self.source_label.setText(
                self._format_html(item.source_text, font_size=self._text_pt(15), color="#FFFFFF", italic=True, weight=500)
            )
        self._sync_label_heights()

    def _text_pt(self, value: int) -> int:
        return pt(value + self._font_boost)

    def _build_section(self) -> tuple[QWidget, QLabel]:
        section = QWidget()
        layout = QVBoxLayout(section)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(0)
        label = self._build_text_label()
        layout.addWidget(label)
        return section, label

    @staticmethod
    def _build_divider() -> QFrame:
        divider = QFrame()
        divider.setFixedHeight(scale(1))
        divider.setStyleSheet("background: rgba(255, 255, 255, 0.22); border: none;")
        divider.setVisible(False)
        return divider

    @staticmethod
    def _build_text_label() -> QLabel:
        label = QLabel()
        label.setWordWrap(True)
        label.setAlignment(Qt.AlignCenter)
        label.setTextFormat(Qt.RichText)
        label.setTextInteractionFlags(Qt.TextSelectableByMouse)
        label.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Preferred)
        label.setStyleSheet("background: transparent;")
        return label

    def _sync_label_heights(self) -> None:
        for label in (
            self.arabic_title_label,
            self.arabic_label,
            self.turkish_label,
            self.english_label,
            self.reference_label,
            self.source_label,
        ):
            self._fit_label_height(label)

    @staticmethod
    def _fit_label_height(label: QLabel) -> None:
        width = max(1, label.contentsRect().width() or label.width() or 320)
        document = QTextDocument()
        document.setDefaultFont(label.font())
        document.setHtml(label.text())
        document.setTextWidth(width)
        label.setMinimumHeight(int(document.size().height()) + scale(6))

    @staticmethod
    def _format_html(
        text: str,
        *,
        font_size: int,
        color: str,
        line_height: float = 1.0,
        direction: str = "ltr",
        italic: bool = False,
        weight: int = 400,
        font_family: str = "",
    ) -> str:
        escaped = html.escape(text or MISSING_TEXT).replace("\n", "<br/>")
        font_style = "italic" if italic else "normal"
        font_family_style = f"font-family:{font_family};" if font_family else ""
        return (
            f"<div dir='{direction}' style='"
            f"text-align:center;"
            f"{font_family_style}"
            f"font-size:{font_size}pt;"
            f"color:{color};"
            f"line-height:{line_height};"
            f"font-style:{font_style};"
            f"font-weight:{weight};"
            f"'>"
            f"{escaped}"
            f"</div>"
        )


class MobilePreviewWindow(QWidget):
    def __init__(self, repository: ContentRepository) -> None:
        super().__init__()
        self._navigator = ApprovedContentNavigator(repository)
        self._show_turkish = True
        self._show_english = True
        self._show_arabic = True
        self._type_buttons: dict[str, QPushButton] = {}
        self._language_buttons: dict[str, QPushButton] = {}
        self.setWindowTitle("Mobil Önizleme / Mobile Preview")
        self.resize(scale(540), scale(1020))
        self._build_ui()
        self.refresh()

    def refresh(self) -> None:
        current_type = self._navigator.current_type
        self._navigator.reload()
        self._navigator.set_content_type(current_type)
        self._sync_controls()
        self._sync_view()

    def _build_ui(self) -> None:
        root = QVBoxLayout(self)
        root.setContentsMargins(scale(18), scale(18), scale(18), scale(18))
        root.setSpacing(scale(12))

        title = QLabel("Mobil Önizleme / Mobile Preview")
        title.setStyleSheet(f"font-size: {pt(18)}pt; font-weight: 700;")
        root.addWidget(title)

        selector_row = QHBoxLayout()
        selector_row.setSpacing(scale(8))
        self._type_buttons["ayah"] = self._build_selector_button("Ayet")
        self._type_buttons["hadith"] = self._build_selector_button("Hadis")
        self._type_buttons["esma"] = self._build_selector_button("Esmaül Hüsna")
        self._type_buttons["ayah"].clicked.connect(lambda: self._select_type("ayah"))
        self._type_buttons["hadith"].clicked.connect(lambda: self._select_type("hadith"))
        self._type_buttons["esma"].clicked.connect(lambda: self._select_type("esma"))
        for button in self._type_buttons.values():
            selector_row.addWidget(button)
        root.addLayout(selector_row)

        control_row = QHBoxLayout()
        control_row.setSpacing(scale(10))
        self.kind_badge = QLabel("-")
        self.kind_badge.setAlignment(Qt.AlignCenter)
        self.kind_badge.setFixedHeight(scale(34))
        self.kind_badge.setMinimumWidth(scale(110))
        self.kind_badge.setStyleSheet(
            f"background: #1F7A3E; color: white; border-radius: {scale(17)}px; font-size: {pt(13)}pt; font-weight: 700; padding: 0 {scale(12)}px;"
        )
        self.position_label = QLabel("0 / 0")
        self.position_label.setStyleSheet(f"font-size: {pt(13)}pt; font-weight: 600;")
        self.start_edit = QLineEdit()
        self.start_edit.setMinimumWidth(scale(150))
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
        control_row.addWidget(self.start_edit)
        control_row.addWidget(self.start_btn)
        control_row.addStretch(1)
        control_row.addWidget(self.prev_btn)
        control_row.addWidget(self.next_btn)
        control_row.addWidget(self.reload_btn)
        root.addLayout(control_row)

        phone_shell = QFrame()
        phone_shell.setFixedSize(scale(430), scale(860))
        phone_shell.setStyleSheet(
            f"background: #171717; border: {scale(2)}px solid #2F2F2F; border-radius: {scale(34)}px;"
        )
        phone_layout = QVBoxLayout(phone_shell)
        phone_layout.setContentsMargins(scale(14), scale(18), scale(14), scale(18))

        screen = QFrame()
        screen.setStyleSheet(f"background: #F3EFE2; border-radius: {scale(26)}px;")
        screen_layout = QVBoxLayout(screen)
        screen_layout.setContentsMargins(scale(18), scale(40), scale(18), scale(24))
        screen_layout.setSpacing(scale(14))

        preview_panel = QFrame()
        preview_panel.setStyleSheet(
            f"background: #93BFA2; border: {scale(1)}px solid rgba(31, 122, 62, 0.35); border-radius: {scale(14)}px;"
        )
        preview_layout = QVBoxLayout(preview_panel)
        preview_layout.setContentsMargins(scale(12), scale(10), scale(12), scale(10))
        preview_layout.setSpacing(scale(10))

        top_row = QHBoxLayout()
        top_row.setContentsMargins(0, 0, 0, 0)
        top_row.setSpacing(scale(8))
        self.heading_label = QLabel("-")
        self.heading_label.setAlignment(Qt.AlignCenter)
        self.heading_label.setStyleSheet(f"font-size: {pt(20)}pt; font-weight: 700; color: #111111;")
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

        self.card = MobilePreviewCard()
        preview_layout.addWidget(self.card, 1)

        screen_layout.addWidget(preview_panel)
        screen_layout.addStretch(1)
        phone_layout.addWidget(screen)
        root.addWidget(phone_shell, 0, Qt.AlignHCenter)

        self.meta_label = QLabel("-")
        self.meta_label.setWordWrap(True)
        self.meta_label.setAlignment(Qt.AlignCenter)
        self.meta_label.setStyleSheet(f"font-size: {pt(11)}pt; color: #5A5A5A;")
        root.addWidget(self.meta_label)

    def _select_type(self, kind: str) -> None:
        self._navigator.set_content_type(kind, reset_index=True)
        self._sync_controls()
        self._sync_view()

    def _jump_to_value(self) -> None:
        item = self._navigator.jump_to(self.start_edit.text())
        if item is None and self._navigator.count() > 0:
            self.meta_label.setText("Girilen başlangıç numarası veya referans bulunamadı.")
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
        self.kind_badge.setText(item.kind_label if item is not None else self._kind_label())
        if item is None:
            self.heading_label.setText(self._kind_heading())
            self.meta_label.setText(self._navigator.empty_message())
            return
        self.heading_label.setText(item.heading)
        self.meta_label.setText(f"{item.record_id} | {item.ref}")

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

    def _show_previous(self) -> None:
        self._navigator.go_previous()
        self._sync_view()

    def _show_next(self) -> None:
        self._navigator.go_next()
        self._sync_view()

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
        chip.setStyleSheet(MobilePreviewWindow._toggle_style(True, font_size=resolved_font_size))
        return chip

    @staticmethod
    def _toggle_style(selected: bool, *, font_size: int) -> str:
        if selected:
            return (
                "background: #121212; color: white; border: 2px solid #121212; "
                f"border-radius: {scale(18)}px; font-weight: 700;"
                f"font-size: {font_size}pt;"
            )
        return (
            "background: white; color: #111111; border: 1.5px solid #FFFFFF; "
            f"border-radius: {scale(18)}px; font-weight: 700;"
            f"font-size: {font_size}pt;"
        )

    @staticmethod
    def _selector_style(selected: bool) -> str:
        if selected:
            return (
                "background: #1F7A3E; color: white; border: 1px solid #1F7A3E; "
                f"border-radius: {scale(10)}px; font-size: {pt(12)}pt; font-weight: 700; padding: {scale(6)}px {scale(12)}px;"
            )
        return (
            "background: #F1F1F1; color: #222222; border: 1px solid #D0D0D0; "
            f"border-radius: {scale(10)}px; font-size: {pt(12)}pt; font-weight: 600; padding: {scale(6)}px {scale(12)}px;"
        )
