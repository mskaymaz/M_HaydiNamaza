from __future__ import annotations

import json
from pathlib import Path
from typing import Any

AYAH_COUNTS_BY_SURAH: dict[int, int] = {
    1: 7, 2: 286, 3: 200, 4: 176, 5: 120, 6: 165, 7: 206, 8: 75, 9: 129, 10: 109,
    11: 123, 12: 111, 13: 43, 14: 52, 15: 99, 16: 128, 17: 111, 18: 110, 19: 98, 20: 135,
    21: 112, 22: 78, 23: 118, 24: 64, 25: 77, 26: 227, 27: 93, 28: 88, 29: 69, 30: 60,
    31: 34, 32: 30, 33: 73, 34: 54, 35: 45, 36: 83, 37: 182, 38: 88, 39: 75, 40: 85,
    41: 54, 42: 53, 43: 89, 44: 59, 45: 37, 46: 35, 47: 38, 48: 29, 49: 18, 50: 45,
    51: 60, 52: 49, 53: 62, 54: 55, 55: 78, 56: 96, 57: 29, 58: 22, 59: 24, 60: 13,
    61: 14, 62: 11, 63: 11, 64: 18, 65: 12, 66: 12, 67: 30, 68: 52, 69: 52, 70: 44,
    71: 28, 72: 28, 73: 20, 74: 56, 75: 40, 76: 31, 77: 50, 78: 40, 79: 46, 80: 42,
    81: 29, 82: 19, 83: 36, 84: 25, 85: 22, 86: 17, 87: 19, 88: 26, 89: 30, 90: 20,
    91: 15, 92: 21, 93: 11, 94: 8, 95: 8, 96: 19, 97: 5, 98: 8, 99: 8, 100: 11,
    101: 11, 102: 8, 103: 3, 104: 9, 105: 5, 106: 4, 107: 7, 108: 3, 109: 6, 110: 3,
    111: 5, 112: 4, 113: 5, 114: 6,
}

_BASMALA = "بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ"


def default_tanzil_seed_paths() -> list[Path]:
    repo_root = Path(__file__).resolve().parents[4]
    return [
        repo_root / "assets" / "data" / "daily_content" / "archive" / "ayet1400_tanzil_ar_tr_en_pending_review.json",
        repo_root / "assets" / "data" / "daily_content" / "archive" / "ayahs.pending_review.v1.json",
    ]


def default_tanzil_full_paths() -> dict[str, Path]:
    repo_root = Path(__file__).resolve().parents[4]
    quran_dir = repo_root / "docs" / "Quran"
    return {
        "ar": quran_dir / "quran-uthmani.txt",
        "tr_main": quran_dir / "tr.bulac.txt",
        "tr_alt": quran_dir / "tr.diyanet.txt",
        "en_main": quran_dir / "en.sahih.txt",
        "en_alt": quran_dir / "en.maududi.txt",
    }


def load_tanzil_seed_payload() -> tuple[dict[str, Any], Path]:
    for path in default_tanzil_seed_paths():
        if not path.exists():
            continue
        with path.open("r", encoding="utf-8-sig") as handle:
            payload = json.load(handle)
        if isinstance(payload, dict) and isinstance(payload.get("items"), list):
            return payload, path
    raise FileNotFoundError("Yerel Tanzil ayet seed dosyasi bulunamadi.")


def load_tanzil_full_index() -> tuple[dict[str, dict[str, str]], dict[str, Path]]:
    paths = default_tanzil_full_paths()
    for path in paths.values():
        if not path.exists():
            raise FileNotFoundError(f"Tanzil dosyasi eksik: {path}")

    arabic_lines = _read_lines(paths["ar"])
    index: dict[str, dict[str, str]] = {}
    line_cursor = 0
    for surah in range(1, 115):
        ayah_count = AYAH_COUNTS_BY_SURAH[surah]
        for ayah in range(1, ayah_count + 1):
            if line_cursor >= len(arabic_lines):
                raise ValueError("Arapca Tanzil dosyasi beklenenden kisa.")
            text = arabic_lines[line_cursor]
            line_cursor += 1
            if surah not in {1, 9} and ayah == 1:
                text = _strip_prefixed_basmala(text)
            index[_ref(surah, ayah)] = {"arabic": text}

    _merge_translation_file(index, paths["tr_main"], "tr_main")
    _merge_translation_file(index, paths["tr_alt"], "tr_alt")
    _merge_translation_file(index, paths["en_main"], "en_main")
    _merge_translation_file(index, paths["en_alt"], "en_alt")
    return index, paths


def _read_lines(path: Path) -> list[str]:
    with path.open("r", encoding="utf-8-sig") as handle:
        return [line.rstrip("\n").rstrip("\r") for line in handle if line.strip()]


def _strip_prefixed_basmala(text: str) -> str:
    candidate = text.strip()
    if candidate.startswith(_BASMALA):
        remainder = candidate[len(_BASMALA):].strip()
        return remainder or candidate
    return candidate


def _merge_translation_file(index: dict[str, dict[str, str]], path: Path, target_key: str) -> None:
    with path.open("r", encoding="utf-8-sig") as handle:
        for raw_line in handle:
            line = raw_line.rstrip("\n").rstrip("\r")
            if not line:
                continue
            parts = line.split("|", 2)
            if len(parts) != 3:
                continue
            try:
                surah = int(parts[0])
                ayah = int(parts[1])
            except ValueError:
                continue
            ref = _ref(surah, ayah)
            if ref not in index:
                continue
            index[ref][target_key] = parts[2]


def _ref(surah: int, ayah: int) -> str:
    return f"{surah:03d}/{ayah:03d}"
