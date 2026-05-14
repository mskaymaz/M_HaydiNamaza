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
        normalized.append(
            ContentRecord(
                record_id=record_id.strip(),
                topic=pick_topic(topics, is_hadith),
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

    # 1) first pass: non-cooldown + topic cap
    try_pick(preferred, enforce_cap=True)
    # 2) second pass: non-cooldown without cap (if count not enough)
    if len(chosen) < target_count:
        try_pick(preferred, enforce_cap=False)
    # 3) third pass: cooldown + cap
    if len(chosen) < target_count:
        try_pick(fallback, enforce_cap=True)
    # 4) final fill: cooldown without cap
    if len(chosen) < target_count:
        try_pick(fallback, enforce_cap=False)

    return chosen[:target_count]


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

    copy_publish_sources(hadith_payload, ayah_payload)

    months = month_sequence(START_MONTH, MONTH_COUNT)
    used_recent_hadith: deque[set[str]] = deque(maxlen=COOLDOWN_MONTHS)
    used_recent_ayah: deque[set[str]] = deque(maxlen=COOLDOWN_MONTHS)

    monthly_files: list[dict[str, Any]] = []
    for month in months:
        month_seed = int(hashlib.sha256(f"allapp-month:{month}".encode("utf-8")).hexdigest()[:12], 16)
        hadith_cooldown = set().union(*used_recent_hadith) if used_recent_hadith else set()
        ayah_cooldown = set().union(*used_recent_ayah) if used_recent_ayah else set()

        hadith_ids = select_monthly_ids(
            records=hadith_pool,
            target_count=COUNT_PER_TYPE,
            seed=month_seed + 17,
            cooldown_ids=hadith_cooldown,
        )
        ayah_ids = select_monthly_ids(
            records=ayah_pool,
            target_count=COUNT_PER_TYPE,
            seed=month_seed + 31,
            cooldown_ids=ayah_cooldown,
        )

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
