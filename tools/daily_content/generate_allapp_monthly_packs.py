#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import math
import random
from collections import Counter, deque
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[2]
PRIVATE_PUBLISH_DIR = REPO_ROOT / "Besmele" / "data" / "daily_panel" / "publish"
HADITH_SOURCE = PRIVATE_PUBLISH_DIR / "hadiths.v1.approved.json"
AYAH_SOURCE = PRIVATE_PUBLISH_DIR / "ayahs.v1.approved.json"

ALLAPP_ROOT = REPO_ROOT / "AllApp" / "data" / "daily_content" / "v1"
PUBLISH_DIR = ALLAPP_ROOT / "publish"
MONTHLY_DIR = ALLAPP_ROOT / "monthly"
MANIFEST_PATH = ALLAPP_ROOT / "manifest.json"

COUNT_PER_TYPE = 30
COOLDOWN_MONTHS = 3
MONTH_COUNT = 12
START_MONTH = "2026-05"

HADITH_GENERIC_TOPICS = {"hadis_draft_pool"}


@dataclass(frozen=True)
class ContentRecord:
    record_id: str
    topic: str
    is_long: bool


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)
    if not isinstance(data, dict):
        raise ValueError(f"Invalid root object: {path}")
    return data


def save_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")


def month_sequence(start_yyyy_mm: str, count: int) -> list[str]:
    year, month = map(int, start_yyyy_mm.split("-"))
    result: list[str] = []
    y = year
    m = month
    for _ in range(count):
        result.append(f"{y:04d}-{m:02d}")
        m += 1
        if m > 12:
            m = 1
            y += 1
    return result


def pick_topic(raw_topics: list[str], is_hadith: bool) -> str:
    topics = [t.strip() for t in raw_topics if isinstance(t, str) and t.strip()]
    if is_hadith:
        filtered = [t for t in topics if t not in HADITH_GENERIC_TOPICS]
        if filtered:
            return filtered[0]
    if topics:
        return topics[0]
    return "genel"


def normalize_records(records: list[dict[str, Any]], is_hadith: bool) -> list[ContentRecord]:
    normalized: list[ContentRecord] = []
    for record in records:
        record_id = record.get("id")
        if not isinstance(record_id, str) or not record_id.strip():
            continue
        raw_topics = record.get("topics", [])
        topics = raw_topics if isinstance(raw_topics, list) else []
        tr_text = ""
        if is_hadith:
            # Hadith dataset Turkish main body is in `text`.
            raw_text = record.get("text", "")
            tr_text = raw_text if isinstance(raw_text, str) else ""
        else:
            # Ayah dataset Turkish content is in `translation`.
            raw_text = record.get("translation", "")
            tr_text = raw_text if isinstance(raw_text, str) else ""

        normalized.append(
            ContentRecord(
                record_id=record_id.strip(),
                topic=pick_topic(topics, is_hadith),
                is_long=len(tr_text.strip()) > 300,
            )
        )
    return normalized


def topic_cap(total_count: int, distinct_topics: int) -> int:
    if distinct_topics <= 0:
        return total_count
    target_topics = min(8, distinct_topics)
    return max(3, math.ceil(total_count / target_topics))


def select_monthly_ids(
    records: list[ContentRecord],
    target_count: int,
    seed: int,
    cooldown_ids: set[str],
) -> list[str]:
    rng = random.Random(seed)
    shuffled = records[:]
    rng.shuffle(shuffled)

    distinct = len({r.topic for r in shuffled})
    cap = topic_cap(target_count, distinct)
    topic_counts: Counter[str] = Counter()

    preferred = [r for r in shuffled if r.record_id not in cooldown_ids]
    fallback = [r for r in shuffled if r.record_id in cooldown_ids]
    preferred_short = [r for r in preferred if not r.is_long]
    preferred_long = [r for r in preferred if r.is_long]
    fallback_short = [r for r in fallback if not r.is_long]
    fallback_long = [r for r in fallback if r.is_long]

    chosen: list[str] = []
    chosen_set: set[str] = set()

    def try_pick(pool: list[ContentRecord], enforce_cap: bool) -> None:
        nonlocal chosen
        for rec in pool:
            if len(chosen) >= target_count:
                return
            if rec.record_id in chosen_set:
                continue
            if enforce_cap and topic_counts[rec.topic] >= cap:
                continue
            chosen.append(rec.record_id)
            chosen_set.add(rec.record_id)
            topic_counts[rec.topic] += 1

    # 1) non-cooldown short + topic cap
    try_pick(preferred_short, enforce_cap=True)
    # 2) non-cooldown short without cap
    if len(chosen) < target_count:
        try_pick(preferred_short, enforce_cap=False)
    # 3) cooldown short + cap
    if len(chosen) < target_count:
        try_pick(fallback_short, enforce_cap=True)
    # 4) cooldown short without cap
    if len(chosen) < target_count:
        try_pick(fallback_short, enforce_cap=False)
    # 5) non-cooldown long + cap
    if len(chosen) < target_count:
        try_pick(preferred_long, enforce_cap=True)
    # 6) non-cooldown long without cap
    if len(chosen) < target_count:
        try_pick(preferred_long, enforce_cap=False)
    # 7) cooldown long + cap
    if len(chosen) < target_count:
        try_pick(fallback_long, enforce_cap=True)
    # 8) cooldown long without cap
    if len(chosen) < target_count:
        try_pick(fallback_long, enforce_cap=False)

    return chosen[:target_count]


def select_ids_from_pool(
    records: list[ContentRecord],
    target_count: int,
    seed: int,
    cooldown_ids: set[str],
) -> list[str]:
    """Topic-balanced selection from a single pool (all short or all long)."""
    if target_count <= 0:
        return []
    return select_monthly_ids(
        records=records,
        target_count=target_count,
        seed=seed,
        cooldown_ids=cooldown_ids,
    )


def copy_publish_sources(hadith_payload: dict[str, Any], ayah_payload: dict[str, Any]) -> None:
    save_json(PUBLISH_DIR / "hadiths.v1.approved.json", hadith_payload)
    save_json(PUBLISH_DIR / "ayahs.v1.approved.json", ayah_payload)


def file_sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    hadith_payload = load_json(HADITH_SOURCE)
    ayah_payload = load_json(AYAH_SOURCE)

    hadith_records = hadith_payload.get("records", [])
    ayah_records = ayah_payload.get("records", [])
    if not isinstance(hadith_records, list) or not isinstance(ayah_records, list):
        raise ValueError("records must be list in source payloads")

    hadith_pool = normalize_records(
        [r for r in hadith_records if isinstance(r, dict)],
        is_hadith=True,
    )
    ayah_pool = normalize_records(
        [r for r in ayah_records if isinstance(r, dict)],
        is_hadith=False,
    )
    hadith_short_pool = [r for r in hadith_pool if not r.is_long]
    hadith_long_pool = [r for r in hadith_pool if r.is_long]
    ayah_short_pool = [r for r in ayah_pool if not r.is_long]
    ayah_long_pool = [r for r in ayah_pool if r.is_long]

    copy_publish_sources(hadith_payload, ayah_payload)

    months = month_sequence(START_MONTH, MONTH_COUNT)
    used_recent_hadith: deque[set[str]] = deque(maxlen=COOLDOWN_MONTHS)
    used_recent_ayah: deque[set[str]] = deque(maxlen=COOLDOWN_MONTHS)
    used_hadith_ids: set[str] = set()
    used_ayah_ids: set[str] = set()

    monthly_files: list[dict[str, Any]] = []
    for month in months:
        month_seed = int(hashlib.sha256(f"allapp-month:{month}".encode("utf-8")).hexdigest()[:12], 16)
        hadith_cooldown = set().union(*used_recent_hadith) if used_recent_hadith else set()
        ayah_cooldown = set().union(*used_recent_ayah) if used_recent_ayah else set()

        available_hadith_short = [r for r in hadith_short_pool if r.record_id not in used_hadith_ids]
        available_hadith_long = [r for r in hadith_long_pool if r.record_id not in used_hadith_ids]
        hadith_short_target = min(COUNT_PER_TYPE, len(available_hadith_short))
        hadith_long_target = COUNT_PER_TYPE - hadith_short_target

        hadith_short_ids = select_ids_from_pool(
            records=available_hadith_short,
            target_count=hadith_short_target,
            seed=month_seed + 17,
            cooldown_ids=hadith_cooldown,
        )
        hadith_long_ids = select_ids_from_pool(
            records=available_hadith_long,
            target_count=hadith_long_target,
            seed=month_seed + 19,
            cooldown_ids=hadith_cooldown,
        )
        hadith_ids = hadith_short_ids + hadith_long_ids

        available_ayah_short = [r for r in ayah_short_pool if r.record_id not in used_ayah_ids]
        available_ayah_long = [r for r in ayah_long_pool if r.record_id not in used_ayah_ids]
        ayah_short_target = min(COUNT_PER_TYPE, len(available_ayah_short))
        ayah_long_target = COUNT_PER_TYPE - ayah_short_target

        ayah_short_ids = select_ids_from_pool(
            records=available_ayah_short,
            target_count=ayah_short_target,
            seed=month_seed + 31,
            cooldown_ids=ayah_cooldown,
        )
        ayah_long_ids = select_ids_from_pool(
            records=available_ayah_long,
            target_count=ayah_long_target,
            seed=month_seed + 37,
            cooldown_ids=ayah_cooldown,
        )
        ayah_ids = ayah_short_ids + ayah_long_ids

        used_hadith_ids.update(hadith_ids)
        used_ayah_ids.update(ayah_ids)

        used_recent_hadith.append(set(hadith_ids))
        used_recent_ayah.append(set(ayah_ids))

        monthly_payload = {
            "schema_version": "1.0.0",
            "content_version": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
            "month": month,
            "seed": month_seed,
            "rules": {
                "count_per_type": COUNT_PER_TYPE,
                "selection_mode": "random_topic_balanced",
                "cooldown_months": COOLDOWN_MONTHS,
                "long_text_policy": "short_first_global_then_long_if_required",
            },
            "ayah_ids": ayah_ids,
            "hadith_ids": hadith_ids,
        }

        month_file = MONTHLY_DIR / f"{month}.json"
        save_json(month_file, monthly_payload)
        monthly_files.append(
            {
                "month": month,
                "path": f"monthly/{month}.json",
                "sha256": file_sha256(month_file),
                "ayah_count": len(ayah_ids),
                "hadith_count": len(hadith_ids),
            }
        )

    manifest = {
        "schema_version": "1.0.0",
        "content_version": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "root": "data/daily_content/v1",
        "publish_files": {
            "ayahs": {
                "path": "publish/ayahs.v1.approved.json",
                "sha256": file_sha256(PUBLISH_DIR / "ayahs.v1.approved.json"),
            },
            "hadiths": {
                "path": "publish/hadiths.v1.approved.json",
                "sha256": file_sha256(PUBLISH_DIR / "hadiths.v1.approved.json"),
            },
        },
        "monthly": monthly_files,
        "selection_contract": {
            "count_per_type": COUNT_PER_TYPE,
            "selection_mode": "random_topic_balanced",
            "cooldown_months": COOLDOWN_MONTHS,
            "seed_mode": "deterministic_by_month",
        },
    }
    save_json(MANIFEST_PATH, manifest)

    print("allapp monthly packs generated")
    print(f"months: {len(monthly_files)}")
    print(f"output: {ALLAPP_ROOT}")


if __name__ == "__main__":
    main()
