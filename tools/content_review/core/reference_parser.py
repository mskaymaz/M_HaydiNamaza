from __future__ import annotations

import re

from .models import ContentKind


SURAH_NAMES_TR: dict[int, str] = {
    1: "Fatiha",
    2: "Bakara",
    3: "Ali Imran",
    4: "Nisa",
    5: "Maide",
    6: "Enam",
    7: "Araf",
    8: "Enfal",
    9: "Tevbe",
    10: "Yunus",
    11: "Hud",
    12: "Yusuf",
    13: "Rad",
    14: "Ibrahim",
    15: "Hicr",
    16: "Nahl",
    17: "Isra",
    18: "Kehf",
    19: "Meryem",
    20: "Taha",
    21: "Enbiya",
    22: "Hac",
    23: "Muminun",
    24: "Nur",
    25: "Furkan",
    26: "Suara",
    27: "Neml",
    28: "Kasas",
    29: "Ankebut",
    30: "Rum",
    31: "Lokman",
    32: "Secde",
    33: "Ahzab",
    34: "Sebe",
    35: "Fatir",
    36: "Yasin",
    37: "Saffat",
    38: "Sad",
    39: "Zumer",
    40: "Mumin",
    41: "Fussilet",
    42: "Sura",
    43: "Zuhruf",
    44: "Duhan",
    45: "Casiye",
    46: "Ahkaf",
    47: "Muhammed",
    48: "Fetih",
    49: "Hucurat",
    50: "Kaf",
    51: "Zariyat",
    52: "Tur",
    53: "Necm",
    54: "Kamer",
    55: "Rahman",
    56: "Vakia",
    57: "Hadid",
    58: "Mucadele",
    59: "Hasr",
    60: "Mumtehine",
    61: "Saff",
    62: "Cuma",
    63: "Munafikun",
    64: "Tegabun",
    65: "Talak",
    66: "Tahrim",
    67: "Mulk",
    68: "Kalem",
    69: "Hakka",
    70: "Mearic",
    71: "Nuh",
    72: "Cin",
    73: "Muzzemmil",
    74: "Mudessir",
    75: "Kiyame",
    76: "Insan",
    77: "Murselat",
    78: "Nebe",
    79: "Naziat",
    80: "Abese",
    81: "Tekvir",
    82: "Infitar",
    83: "Mutaffifin",
    84: "Insikak",
    85: "Buruc",
    86: "Tarik",
    87: "Ala",
    88: "Gasiye",
    89: "Fecr",
    90: "Beled",
    91: "Sems",
    92: "Leyl",
    93: "Duha",
    94: "Insirah",
    95: "Tin",
    96: "Alak",
    97: "Kadir",
    98: "Beyyine",
    99: "Zilzal",
    100: "Adiyat",
    101: "Karia",
    102: "Tekasur",
    103: "Asr",
    104: "Humeze",
    105: "Fil",
    106: "Kureys",
    107: "Maun",
    108: "Kevser",
    109: "Kafirun",
    110: "Nasr",
    111: "Tebbet",
    112: "Ihlas",
    113: "Felak",
    114: "Nas",
}


def normalize_reference(kind: ContentKind, raw_value: str) -> dict[str, object]:
    if kind == "ayah":
        return normalize_ayah_reference(raw_value)
    return normalize_hadith_reference(raw_value)


def normalize_ayah_reference(raw_value: str) -> dict[str, object]:
    text = str(raw_value or "").strip()
    range_match = re.fullmatch(r"0*(\d{1,3})\s*[/:\-]\s*0*(\d{1,3})\s*-\s*0*(\d{1,3})", text)
    if range_match:
        surah_number = int(range_match.group(1))
        ayah_start = int(range_match.group(2))
        ayah_end = int(range_match.group(3))
        if not (1 <= surah_number <= 114):
            raise ValueError("Sure numarasi 1-114 arasinda olmali.")
        if ayah_start <= 0 or ayah_end <= 0:
            raise ValueError("Ayet numaralari pozitif olmali.")
        if ayah_end < ayah_start:
            raise ValueError("Ayet araligi artan sirada olmali.")
        ref = f"{surah_number:03d}/{ayah_start:03d}-{ayah_end:03d}"
        return {
            "id": ref,
            "ref": ref,
            "surah_number": surah_number,
            "ayah_number": ayah_start,
            "ayah_start": ayah_start,
            "ayah_end": ayah_end,
            "ayah_count": ayah_end - ayah_start + 1,
            "record_type": "range",
            "surah_name": SURAH_NAMES_TR.get(surah_number, f"Sure {surah_number}"),
        }
    match = re.fullmatch(r"0*(\d{1,3})\s*[/:\-]\s*0*(\d{1,3})", text)
    if not match:
        raise ValueError("Ayet referansi `sure/ayet` veya `sure/ayet1-ayet2` formatinda olmali.")
    surah_number = int(match.group(1))
    ayah_number = int(match.group(2))
    if not (1 <= surah_number <= 114):
        raise ValueError("Sure numarasi 1-114 arasinda olmali.")
    if ayah_number <= 0:
        raise ValueError("Ayet numarasi pozitif olmali.")
    ref = f"{surah_number:03d}/{ayah_number:03d}"
    return {
        "id": ref,
        "ref": ref,
        "surah_number": surah_number,
        "ayah_number": ayah_number,
        "ayah_start": ayah_number,
        "ayah_end": ayah_number,
        "ayah_count": 1,
        "record_type": "single",
        "surah_name": SURAH_NAMES_TR.get(surah_number, f"Sure {surah_number}"),
    }


def normalize_hadith_reference(raw_value: str) -> dict[str, object]:
    digits = re.sub(r"[^\d]", "", str(raw_value or ""))
    if not digits:
        raise ValueError("Hadis referansi sayisal hadis no icermeli.")
    hadith_number = int(digits)
    if hadith_number <= 0:
        raise ValueError("Hadis numarasi pozitif olmali.")
    return {
        "id": f"hadith_{hadith_number:06d}",
        "ref": f"riyazussalihin/{hadith_number}",
        "hadith_number": hadith_number,
    }
