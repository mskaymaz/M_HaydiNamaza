# Qibla direction data architecture

## Decision

The app compass keeps using the phone heading sensor for live device direction.
The target qibla angle for Diyanet/Türkiye locations is read from a bundled local
JSON asset exported from the private Avkat workspace.

The app must not call external websites for qibla direction while local data is
available.

## Data source

Private source workspace:

```text
D:\Code\mskaymaz\Avkat
```

Source data type:

```text
Awqat Salah CityDetail
GET /api/Place/CityDetail/{cityId}
```

Important source fields:

```text
qiblaAngle
geographicQiblaAngle
distanceToKaaba
id
name
city
country
```

## App asset

Bundled Flutter asset path:

```text
assets/data/qibla/locations.latest.json
```

This file is generated from Avkat and contains one record per Türkiye location.
The expected location count is 869.

## Runtime logic

Two values are handled independently:

```text
1. Device heading from FlutterCompass
2. Target qibla angle from Avkat CityDetail asset
```

Needle rotation formula:

```text
needleRotation = qiblaAngle - deviceHeading
```

The angle is normalized to 0..360 before conversion to radians.

## Fallback

If the selected location has no Avkat qibla record, the existing coordinate-based
qibla bearing calculator remains the fallback. The compass screen must keep
working, but the UI shows that coordinate fallback is being used.

## Needle color rule

When a qibla target angle is available:

```text
Red needle  : phone heading is not aligned with qibla direction
Green needle: phone heading is within tolerance of qibla direction
```

Current tolerance is 5 degrees.

## Generator command

From the Flutter repo root:

```powershell
python tools\qibla\build_qibla_locations_asset.py `
  --avkat-root "D:\Code\mskaymaz\Avkat" `
  --output "assets\data\qibla\locations.latest.json"
```

Do not commit raw Avkat folders, `.env`, tokens, or private credentials.
