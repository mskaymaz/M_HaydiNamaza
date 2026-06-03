from __future__ import annotations

import re
import unicodedata


def normalize_storage_text(text: str) -> str:
    value = text.replace("\ufeff", "")
    value = value.replace("\r\n", "\n").replace("\r", "\n")
    value = value.replace("\u00a0", " ")
    value = unicodedata.normalize("NFC", value)
    lines = [line.rstrip() for line in value.split("\n")]
    value = "\n".join(lines).strip()
    value = re.sub(r"\n{3,}", "\n\n", value)
    value = re.sub(r"[ \t]{2,}", " ", value)
    return value


def normalize_record_texts(ar: str, tr: str, en: str) -> tuple[str, str, str]:
    return (
        normalize_storage_text(ar),
        normalize_storage_text(tr),
        normalize_storage_text(en),
    )
