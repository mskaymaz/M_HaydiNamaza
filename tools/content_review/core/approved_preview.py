from __future__ import annotations

from dataclasses import dataclass

from .models import AyahRecord, BaseRecord, EsmaRecord, HadithRecord
from .storage import ContentRepository


MISSING_TEXT = "Eksik veri"
PREVIEW_TYPES = ("ayah", "hadith", "esma")


@dataclass(slots=True)
class MobilePreviewItem:
    record_id: str
    ref: str
    kind: str
    kind_label: str
    heading: str
    arabic_title_text: str
    arabic_text: str
    turkish_text: str
    english_text: str
    reference_text: str
    source_text: str
    order_number: int | None = None
    search_tokens: tuple[str, ...] = ()


class ApprovedContentNavigator:
    def __init__(self, repository: ContentRepository) -> None:
        self._repository = repository
        self._items_by_type: dict[str, list[MobilePreviewItem]] = {key: [] for key in PREVIEW_TYPES}
        self._current_type = "ayah"
        self._indices: dict[str, int] = {key: 0 for key in PREVIEW_TYPES}

    @property
    def current_type(self) -> str:
        return self._current_type

    def reload(self) -> None:
        self._repository.reload()
        self._items_by_type["ayah"] = self._load_items("ayah")
        self._items_by_type["hadith"] = self._load_items("hadith")
        self._items_by_type["esma"] = self._load_items("esma")
        for kind in PREVIEW_TYPES:
            items = self._items_by_type[kind]
            self._indices[kind] = 0 if not items else min(max(self._indices[kind], 0), len(items) - 1)

    def set_content_type(self, kind: str, *, reset_index: bool = False) -> None:
        if kind not in PREVIEW_TYPES:
            return
        self._current_type = kind
        if reset_index:
            self._indices[kind] = 0

    def count(self) -> int:
        return len(self._items_by_type[self._current_type])

    def current_index(self) -> int:
        return self._indices[self._current_type]

    def current_item(self) -> MobilePreviewItem | None:
        items = self._items_by_type[self._current_type]
        if not items:
            return None
        return items[self._indices[self._current_type]]

    def can_go_previous(self) -> bool:
        return self._indices[self._current_type] > 0

    def can_go_next(self) -> bool:
        return self._indices[self._current_type] + 1 < len(self._items_by_type[self._current_type])

    def go_previous(self) -> MobilePreviewItem | None:
        if self.can_go_previous():
            self._indices[self._current_type] -= 1
        return self.current_item()

    def go_next(self) -> MobilePreviewItem | None:
        if self.can_go_next():
            self._indices[self._current_type] += 1
        return self.current_item()

    def jump_to(self, raw_value: str) -> MobilePreviewItem | None:
        value = raw_value.strip()
        if not value:
            return self.current_item()
        items = self._items_by_type[self._current_type]
        if not items:
            return None
        lowered = value.casefold()
        for index, item in enumerate(items):
            if lowered in {token.casefold() for token in item.search_tokens if token.strip()}:
                self._indices[self._current_type] = index
                return item
        try:
            number = int(value)
        except ValueError:
            return None
        for index, item in enumerate(items):
            if item.order_number == number:
                self._indices[self._current_type] = index
                return item
        if 1 <= number <= len(items):
            self._indices[self._current_type] = number - 1
            return items[number - 1]
        return None

    def position_label(self) -> str:
        total = self.count()
        if total == 0:
            return "0 / 0"
        return f"{self.current_index() + 1} / {total}"

    def empty_message(self) -> str:
        if self._current_type == "ayah":
            return "Onaylı ayet kaydı bulunamadı."
        if self._current_type == "hadith":
            return "Onaylı hadis kaydı bulunamadı."
        return "Onaylı Esmaül Hüsna kaydı bulunamadı."

    def start_hint(self) -> str:
        if self._current_type == "hadith":
            return "Hadis no veya sıra no"
        if self._current_type == "esma":
            return "Esma no veya sıra no"
        return "Sıra no veya referans"

    def _load_items(self, kind: str) -> list[MobilePreviewItem]:
        items: list[MobilePreviewItem] = []
        for position, record in enumerate(self._repository.list_approved_records(kind), start=1):
            if kind == "ayah":
                items.append(self._build_ayah_item(record, position))
            elif kind == "hadith":
                items.append(self._build_hadith_item(record, position))
            else:
                items.append(self._build_esma_item(record, position))
        return items

    def _build_ayah_item(self, record: BaseRecord, position: int) -> MobilePreviewItem:
        if not isinstance(record, AyahRecord):
            raise TypeError("Expected AyahRecord for ayah preview item.")
        raw = record.raw if isinstance(record.raw, dict) else {}
        source_text = self._pick_text(raw.get("source_note"), raw.get("source_tr"), self._meal_source_text(raw))
        reference_text = self._build_ayah_reference(record)
        return MobilePreviewItem(
            record_id=record.id,
            ref=record.ref,
            kind="ayah",
            kind_label="Ayet",
            heading="Günün Ayeti",
            arabic_title_text="",
            arabic_text=self._safe_text(record.ar),
            turkish_text=self._safe_text(record.tr),
            english_text=self._safe_text(record.en),
            reference_text=reference_text,
            source_text=source_text,
            order_number=position,
            search_tokens=(record.id, record.ref, reference_text, str(position)),
        )

    def _build_hadith_item(self, record: BaseRecord, position: int) -> MobilePreviewItem:
        if not isinstance(record, HadithRecord):
            raise TypeError("Expected HadithRecord for hadith preview item.")
        raw = record.raw if isinstance(record.raw, dict) else {}
        archive_record = self._repository.find_archive_record("hadith", record.id) or self._repository.find_archive_record("hadith", record.ref)
        archive_raw = archive_record.raw if archive_record and isinstance(archive_record.raw, dict) else {}
        archive_source = archive_raw.get("sourceInfo") if isinstance(archive_raw.get("sourceInfo"), dict) else {}
        archive_display = archive_source.get("display") if isinstance(archive_source.get("display"), dict) else {}
        archive_tr_ref = archive_source.get("tr") if isinstance(archive_source.get("tr"), dict) else {}
        source_text = self._pick_text(
            record.book_reference_tr,
            record.book_reference_en,
            archive_display.get("tr"),
            archive_display.get("en"),
            archive_tr_ref.get("reference"),
            raw.get("source_note"),
            raw.get("source_tr"),
            raw.get("source_en"),
        )
        reference_text = self._build_hadith_reference(record)
        hadith_number = record.hadith_number
        return MobilePreviewItem(
            record_id=record.id,
            ref=record.ref,
            kind="hadith",
            kind_label="Hadis",
            heading="Günün Hadisi",
            arabic_title_text="",
            arabic_text=self._safe_text(record.ar),
            turkish_text=self._safe_text(record.tr),
            english_text=self._safe_text(record.en),
            reference_text=reference_text,
            source_text=source_text,
            order_number=hadith_number,
            search_tokens=(record.id, record.ref, reference_text, str(position), str(hadith_number or "")),
        )

    def _build_esma_item(self, record: BaseRecord, position: int) -> MobilePreviewItem:
        if not isinstance(record, EsmaRecord):
            raise TypeError("Expected EsmaRecord for esma preview item.")
        raw = record.raw if isinstance(record.raw, dict) else {}
        number = record.esma_number or position
        turkish_text = self._join_lines(record.latin_tr, record.tr)
        english_text = self._join_lines(record.latin_en, record.en)
        reference_text = f"Esmaül Hüsna {number}"
        source_text = self._pick_text(
            raw.get("source_note"),
            raw.get("sourceLabel"),
            raw.get("source_label"),
            "Esmaül Hüsna",
        )
        return MobilePreviewItem(
            record_id=record.id,
            ref=record.ref,
            kind="esma",
            kind_label="Esma",
            heading="Esmaül Hüsna",
            arabic_title_text=self._safe_text(record.arabic_name),
            arabic_text=self._safe_text(record.ar),
            turkish_text=self._safe_text(turkish_text),
            english_text=self._safe_text(english_text),
            reference_text=reference_text,
            source_text=source_text,
            order_number=number,
            search_tokens=(
                record.id,
                record.ref,
                record.slug,
                reference_text,
                record.latin_tr,
                record.latin_en,
                str(position),
                str(number),
            ),
        )

    def _build_ayah_reference(self, record: AyahRecord) -> str:
        surah_name = self._pick_text(record.surah_name)
        ayah_start = record.ayah_number
        ayah_end = record.ayah_end_number
        if ayah_start is None:
            ayah_text = MISSING_TEXT
        elif ayah_end is not None and ayah_end != ayah_start:
            ayah_text = f"{ayah_start}-{ayah_end}"
        else:
            ayah_text = str(ayah_start)
        return f"{surah_name} {ayah_text}".strip()

    def _build_hadith_reference(self, record: HadithRecord) -> str:
        raw = record.raw if isinstance(record.raw, dict) else {}
        collection = self._pick_text(raw.get("collection"), self._collection_from_ref(record.ref))
        hadith_number = str(record.hadith_number) if record.hadith_number is not None else self._digits_from_ref(record.ref)
        return f"{collection} {hadith_number or MISSING_TEXT}".strip()

    @staticmethod
    def _join_lines(first: str, second: str) -> str:
        values = [value.strip() for value in (first, second) if value and value.strip()]
        return "\n".join(values)

    @staticmethod
    def _meal_source_text(raw: dict[str, object]) -> str:
        meal_source = str(raw.get("meal_source") or "").strip()
        if not meal_source:
            return ""
        return f"Meâl kaynağı: {meal_source}"

    @staticmethod
    def _collection_from_ref(ref: str) -> str:
        if ref.startswith("riyazussalihin/"):
            return "Riyazus Salihin"
        return ref.split("/")[0].replace("_", " ").strip() if ref else ""

    @staticmethod
    def _digits_from_ref(ref: str) -> str:
        if not ref:
            return ""
        tail = ref.split("/")[-1].strip()
        return tail if tail else ""

    @staticmethod
    def _safe_text(value: object) -> str:
        text = str(value or "").strip()
        return text if text else MISSING_TEXT

    @staticmethod
    def _pick_text(*values: object) -> str:
        for value in values:
            text = str(value or "").strip()
            if text:
                return text
        return MISSING_TEXT
