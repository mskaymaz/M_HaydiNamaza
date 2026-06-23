#!/usr/bin/env python3
import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

ENDPOINT = "GET /api/Place/CityDetail/{cityId}"


def parse_number(value, number_type):
    text = str(value or "").strip().replace(",", ".")
    if not text:
        return None
    try:
        if number_type is int:
            return int(float(text))
        return number_type(text)
    except ValueError:
        return None


def unwrap_city_detail(data):
    if not isinstance(data, dict):
        return {}
    direct_keys = {"id", "name", "code", "qiblaAngle", "geographicQiblaAngle"}
    if direct_keys.intersection(data.keys()):
        return data
    for key in ("data", "result", "item", "value"):
        nested = data.get(key)
        if isinstance(nested, dict) and direct_keys.intersection(nested.keys()):
            return nested
    return data


def get_value(data, *keys):
    if not isinstance(data, dict):
        return None
    lower_map = {str(key).lower(): value for key, value in data.items()}
    for key in keys:
        if key in data:
            return data[key]
        lowered = key.lower()
        if lowered in lower_map:
            return lower_map[lowered]
    return None


def build_from_raw(avkat_root: Path):
    raw_root = avkat_root / "raw" / "place" / "city-detail"
    if not raw_root.exists():
        return None

    records = []
    invalid_paths = []
    for path in sorted(raw_root.rglob("*.latest.json")):
        raw_data = json.loads(path.read_text(encoding="utf-8-sig"))
        data = unwrap_city_detail(raw_data)
        location_id = parse_number(get_value(data, "id", "cityId", "locationId"), int)
        qibla_angle = parse_number(
            get_value(data, "qiblaAngle", "angleDegrees", "qiblaAngleDegrees"),
            float,
        )
        geographic_angle = parse_number(
            get_value(data, "geographicQiblaAngle", "geographicAngleDegrees"),
            float,
        )
        if qibla_angle is None:
            qibla_angle = geographic_angle
        if location_id is None or qibla_angle is None:
            invalid_paths.append(path)
            continue
        raw_file = path.relative_to(avkat_root).as_posix()
        records.append(
            {
                "locationId": location_id,
                "locationCode": str(get_value(data, "code", "locationCode") or "").strip(),
                "locationName": str(get_value(data, "name", "locationName") or "").strip(),
                "stateCode": str(get_value(data, "city", "stateCode") or "").strip(),
                "stateName": str(get_value(data, "city", "stateName") or "").strip(),
                "countryName": str(get_value(data, "country", "countryName") or "").strip(),
                "qibla": {
                    "angleDegrees": qibla_angle,
                    "geographicAngleDegrees": geographic_angle,
                    "distanceToKaabaKm": parse_number(
                        get_value(data, "distanceToKaaba", "distanceToKaabaKm"),
                        float,
                    ),
                },
                "source": {
                    "endpoint": ENDPOINT,
                    "rawFile": raw_file,
                },
            }
        )

    if invalid_paths:
        sample = "\n".join(str(path) for path in invalid_paths[:10])
        raise ValueError(
            f"Invalid CityDetail qibla records: {len(invalid_paths)} file(s)\n{sample}"
        )

    return {
        "metadata": {
            "project": "Avkat",
            "dataset": "qibla_locations",
            "source": "Awqat Salah CityDetail",
            "generatedAt": datetime.now(timezone.utc).isoformat(),
            "totalLocations": len(records),
            "expectedLocations": len(records),
            "isComplete": True,
        },
        "locations": records,
    }


def load_processed(avkat_root: Path):
    path = avkat_root / "processed" / "prayer" / "qibla" / "locations.latest.json"
    if not path.exists():
        return None
    return json.loads(path.read_text(encoding="utf-8-sig"))


def main():
    parser = argparse.ArgumentParser(
        description="Build the bundled qibla asset from Avkat CityDetail data."
    )
    parser.add_argument("--avkat-root", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--expected", default=869, type=int)
    args = parser.parse_args()

    data = load_processed(args.avkat_root) or build_from_raw(args.avkat_root)
    if data is None:
        raise SystemExit("No processed qibla JSON or raw CityDetail folder was found.")

    locations = data.get("locations")
    if not isinstance(locations, list):
        raise SystemExit("Invalid qibla dataset: locations array is missing.")
    if len(locations) != args.expected:
        raise SystemExit(
            f"Invalid qibla dataset size: expected {args.expected}, got {len(locations)}."
        )

    metadata = data.setdefault("metadata", {})
    metadata["expectedLocations"] = args.expected
    metadata["isComplete"] = len(locations) == args.expected

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(data, ensure_ascii=False, separators=(",", ":")) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {len(locations)} qibla locations to {args.output}")


if __name__ == "__main__":
    main()
