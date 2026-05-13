#!/usr/bin/env python3
"""
TASK-05 Daily Ayah Dataset Generator (scaffold)

- Produces draft-only ayah records.
- Supports dry-run and reference-only mode when API credentials are missing.
- Does not touch app integration or prayer-time logic.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from html import unescape
from pathlib import Path
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent.parent

DEFAULT_SEED_FILE = REPO_ROOT / "tools" / "daily_content" / "ayah_seed_refs.json"
DEFAULT_OUTPUT_FILE = REPO_ROOT / "Besmele" / "data" / "daily_panel" / "ayahs_draft.json"
DEFAULT_REF_FILE = REPO_ROOT / "Besmele" / "data" / "daily_panel" / "used_references.json"

REF_PATTERN = re.compile(r"^(\d+):(\d+)$")
TAG_RE = re.compile(r"<[^>]+>")


@dataclass(frozen=True)
class AyahRef:
    surah_number: int
    ayah_number: int

    @property
    def verse_key(self) -> str:
        return f"{self.surah_number}:{self.ayah_number}"


def load_json(path: Path, default: Any) -> Any:
    if not path.exists():
        return default
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def save_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="\n") as f:
        json.dump(value, f, ensure_ascii=False, indent=2)
        f.write("\n")


def normalize_text(value: Any) -> str:
    if value is None:
        return ""
    text = unescape(str(value)).strip()
    text = TAG_RE.sub("", text)
    return " ".join(text.split())


def parse_seed_refs(seed_file: Path) -> list[AyahRef]:
    seed_data = load_json(seed_file, {})
    refs = seed_data.get("references", [])
    parsed: list[AyahRef] = []
    for raw in refs:
        raw_s = str(raw).strip()
        match = REF_PATTERN.match(raw_s)
        if not match:
            raise ValueError(f"Invalid ayah ref in seed file: {raw_s}")
        parsed.append(AyahRef(int(match.group(1)), int(match.group(2))))
    return parsed


def http_get_json(url: str, headers: dict[str, str], timeout_sec: int = 30) -> Any:
    req = Request(url=url, headers=headers, method="GET")
    with urlopen(req, timeout=timeout_sec) as resp:  # nosec B310
        body = resp.read().decode("utf-8")
    return json.loads(body)


def fetch_diyanet_surah_name(dib_base_url: str, dib_token: str, surah_number: int) -> str:
    url = f"{dib_base_url.rstrip('/')}/api/v1/chapters"
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {dib_token}",
    }
    data = http_get_json(url, headers=headers)
    chapters = data.get("data", [])
    for row in chapters:
        sid = row.get("SureId") or row.get("sure_id") or row.get("id")
        if str(sid) == str(surah_number):
            return normalize_text(row.get("SureNameTurkish") or row.get("name_tr"))
    return ""


def fetch_diyanet_ayah(
    dib_base_url: str, dib_token: str, ayah_ref: AyahRef
) -> tuple[str, str]:
    url = f"{dib_base_url.rstrip('/')}/api/v1/chapters/{ayah_ref.surah_number}"
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {dib_token}",
    }
    data = http_get_json(url, headers=headers)
    rows = data.get("data", [])
    for row in rows:
        verse_no = (
            row.get("verse_id_in_surah")
            or row.get("VerseIdInSurah")
            or row.get("verse_number")
            or row.get("AyetNo")
        )
        if str(verse_no) != str(ayah_ref.ayah_number):
            continue
        arabic = normalize_text(
            row.get("arabic_script", {}).get("text")
            or row.get("ArabicText")
            or row.get("text_ar")
            or row.get("text")
        )
        turkish = normalize_text(
            row.get("translation", {}).get("text")
            or row.get("Translation")
            or row.get("text_tr")
        )
        return arabic, turkish
    return "", ""


def fetch_qf_english_ayah(
    qf_base_url: str,
    qf_token: str,
    qf_client_id: str,
    ayah_ref: AyahRef,
    resource_id: int = 131,
) -> str:
    query = urlencode(
        {
            "translations": str(resource_id),
            "translation_fields": "resource_id,text,verse_key,resource_name",
            "fields": "text_uthmani",
        }
    )
    url = f"{qf_base_url.rstrip('/')}/verses/by_key/{ayah_ref.verse_key}?{query}"
    headers = {
        "x-auth-token": qf_token,
        "x-client-id": qf_client_id,
        "Content-Type": "application/json",
    }
    data = http_get_json(url, headers=headers)
    verse = data.get("verse", {})
    translations = verse.get("translations", [])
    for tr in translations:
        if int(tr.get("resource_id", -1)) == resource_id:
            return normalize_text(tr.get("text"))
    return ""


def record_fingerprints(record: dict[str, Any]) -> dict[str, str]:
    return {
        "id": normalize_text(record.get("id")),
        "surah_ayah": f"{record.get('surah_number')}:{record.get('ayah_number')}",
        "source_ar": normalize_text(record.get("source_ar")),
        "arabic_text": normalize_text(record.get("text", {}).get("ar")),
        "turkish_translation": normalize_text(record.get("translation", {}).get("tr")),
        "english_translation": normalize_text(record.get("translation", {}).get("en")),
    }


def build_draft_record(
    ayah_ref: AyahRef,
    surah_name_tr: str,
    text_ar: str,
    tr_translation: str,
    en_translation: str,
) -> dict[str, Any]:
    return {
        "id": f"ayah-{ayah_ref.surah_number}-{ayah_ref.ayah_number}",
        "type": "ayah",
        "surah_name": surah_name_tr or f"Sure {ayah_ref.surah_number}",
        "surah_number": ayah_ref.surah_number,
        "ayah_number": ayah_ref.ayah_number,
        "text": {
            "ar": text_ar,
        },
        "translation": {
            "tr": tr_translation,
            "en": en_translation,
        },
        "source_ar": f"diyanet_api_v1:{ayah_ref.verse_key}",
        "source_tr": f"diyanet_api_v1:{ayah_ref.verse_key}",
        "source_en": f"quran_foundation_resource_131:{ayah_ref.verse_key}",
        "meal_source": {
            "tr": "Diyanet Isleri Baskanligi Meali",
            "en": "Dr. Mustafa Khattab (resource_id=131)",
        },
        "source_note": "requires human verification",
        "topics": [],
        "status": "draft",
        "approval": {
            "approved_by": None,
            "approved_at": None,
            "review_note": "requires human verification",
        },
    }


def has_duplicate(
    fingerprints: dict[str, str],
    seen: dict[str, set[str]],
) -> tuple[bool, str]:
    for key in (
        "id",
        "surah_ayah",
        "source_ar",
        "arabic_text",
        "turkish_translation",
        "english_translation",
    ):
        value = fingerprints.get(key, "")
        if value and value in seen[key]:
            return True, key
    return False, ""


def add_to_seen(fingerprints: dict[str, str], seen: dict[str, set[str]]) -> None:
    for key, value in fingerprints.items():
        if value:
            seen[key].add(value)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate draft ayah dataset scaffold.")
    parser.add_argument("--seed-file", default=str(DEFAULT_SEED_FILE))
    parser.add_argument("--output-file", default=str(DEFAULT_OUTPUT_FILE))
    parser.add_argument("--refs-file", default=str(DEFAULT_REF_FILE))
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--dib-base-url", default=os.getenv("DIB_KURAN_API_BASE_URL", "https://api.diyanet.gov.tr"))
    parser.add_argument("--dib-token", default=os.getenv("DIB_KURAN_API_TOKEN", ""))
    parser.add_argument(
        "--qf-base-url",
        default=os.getenv("QF_CONTENT_API_BASE_URL", "https://apis.quran.foundation/content/api/v4"),
    )
    parser.add_argument("--qf-token", default=os.getenv("QF_API_TOKEN", ""))
    parser.add_argument("--qf-client-id", default=os.getenv("QF_CLIENT_ID", ""))
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    seed_file = Path(args.seed_file)
    output_file = Path(args.output_file)
    refs_file = Path(args.refs_file)

    refs = parse_seed_refs(seed_file)
    existing_drafts = load_json(output_file, [])
    if not isinstance(existing_drafts, list):
        raise ValueError(f"Output file must contain a JSON array: {output_file}")

    seen = {
        "id": set(),
        "surah_ayah": set(),
        "source_ar": set(),
        "arabic_text": set(),
        "turkish_translation": set(),
        "english_translation": set(),
    }
    for item in existing_drafts:
        add_to_seen(record_fingerprints(item), seen)

    can_fetch_diyanet = bool(args.dib_token)
    can_fetch_qf = bool(args.qf_token and args.qf_client_id)
    reference_only = not (can_fetch_diyanet and can_fetch_qf)

    generated: list[dict[str, Any]] = []
    skipped: list[dict[str, str]] = []
    surah_name_cache: dict[int, str] = {}

    for ayah_ref in refs:
        if reference_only:
            skipped.append(
                {"ref": ayah_ref.verse_key, "reason": "missing_api_credentials_reference_only"}
            )
            continue

        try:
            if ayah_ref.surah_number not in surah_name_cache:
                surah_name_cache[ayah_ref.surah_number] = fetch_diyanet_surah_name(
                    args.dib_base_url, args.dib_token, ayah_ref.surah_number
                )

            text_ar, tr_translation = fetch_diyanet_ayah(
                args.dib_base_url, args.dib_token, ayah_ref
            )
            en_translation = fetch_qf_english_ayah(
                args.qf_base_url, args.qf_token, args.qf_client_id, ayah_ref
            )
        except (HTTPError, URLError, TimeoutError, ValueError, json.JSONDecodeError) as exc:
            skipped.append({"ref": ayah_ref.verse_key, "reason": f"fetch_error:{type(exc).__name__}"})
            continue

        if not (text_ar and tr_translation and en_translation):
            skipped.append({"ref": ayah_ref.verse_key, "reason": "missing_required_text"})
            continue

        record = build_draft_record(
            ayah_ref=ayah_ref,
            surah_name_tr=surah_name_cache.get(ayah_ref.surah_number, ""),
            text_ar=text_ar,
            tr_translation=tr_translation,
            en_translation=en_translation,
        )
        fp = record_fingerprints(record)
        is_dup, dup_field = has_duplicate(fp, seen)
        if is_dup:
            skipped.append({"ref": ayah_ref.verse_key, "reason": f"duplicate:{dup_field}"})
            continue

        generated.append(record)
        add_to_seen(fp, seen)

    updated_drafts = existing_drafts + generated

    refs_data = load_json(refs_file, {})
    if not isinstance(refs_data, dict):
        refs_data = {}
    refs_data.setdefault("ayah", {})
    refs_data.setdefault("hadith", {})
    refs_data.setdefault("meta", {})

    refs_data["ayah"]["seed_file"] = str(seed_file.relative_to(REPO_ROOT))
    refs_data["ayah"]["selected_refs"] = [r.verse_key for r in refs]
    refs_data["ayah"]["used_ids"] = [item.get("id") for item in updated_drafts if item.get("id")]
    refs_data["ayah"]["used_source_keys"] = [
        item.get("source_ar") for item in updated_drafts if item.get("source_ar")
    ]
    refs_data["ayah"]["skipped_refs"] = skipped
    refs_data["meta"]["last_updated"] = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    refs_data["meta"]["generator"] = "tools/daily_content/generate_ayahs_draft.py"
    refs_data["meta"]["mode"] = "reference_only" if reference_only else "api_fetch"

    print("=== TASK-05 Ayah Dataset Generator ===")
    print(f"seed refs: {len(refs)}")
    print(f"existing drafts: {len(existing_drafts)}")
    print(f"generated drafts: {len(generated)}")
    print(f"skipped refs: {len(skipped)}")
    print(f"mode: {'reference_only' if reference_only else 'api_fetch'}")

    if args.dry_run:
        print("dry-run enabled: no files written.")
        return 0

    save_json(output_file, updated_drafts)
    save_json(refs_file, refs_data)
    print(f"written: {output_file}")
    print(f"written: {refs_file}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print("interrupted", file=sys.stderr)
        raise SystemExit(130)
