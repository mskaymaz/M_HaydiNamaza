# M_HaydiNamaza — Diyanet Free Infrastructure & Shared Data Tasks

## Purpose

Integrate Diyanet prayer-time data into `M_HaydiNamaza` first, while designing the same data contract so `D_HaydiNamaza` can consume the exact same published files later.

The system must be designed for a zero-cost operating model. The project currently has no monetization target, so every infrastructure choice must avoid paid or metered dependencies unless explicitly approved later.

---

## Non-negotiable Cost Rule

1. Do not introduce any paid service into the default architecture.
2. Do not require Cloudflare paid plans for the first implementation.
3. Do not use Cloudflare Workers, KV, D1, Durable Objects, Logpush, paid Cache Analytics, paid databases, or paid monitoring as required runtime dependencies.
4. If any implementation step requires billing setup, a paid plan, or usage-based charges, stop and report it before implementing.
5. Use only free-tier-compatible static distribution by default.

Current free-tier assumptions must be verified during setup:
- Cloudflare R2 Standard free tier can host the small static JSON dataset.
- Cloudflare CDN/custom domain can serve static files.
- GraphQL Analytics API may be used by an admin-side script for periodic reporting if available on the active plan.
- Workers/KV/D1 must remain optional and disabled unless explicitly approved.

---

## Target Architecture

```text
Private/local Avkat repo
  ↓
Publish-ready Diyanet data generator
  ↓
Cloudflare R2 Standard bucket
  ↓
Cloudflare CDN / custom domain / cache rules
  ↓
M_HaydiNamaza mobile app
  ↓
Local app cache / offline use
```

Later, `D_HaydiNamaza` desktop must consume the same published data contract:

```text
Same Cloudflare R2/CDN public files
  ↓
M_HaydiNamaza mobile
D_HaydiNamaza desktop
```

---

## Key Decisions

1. Diyanet raw data will not be published as-is.
2. The publish format must remove unused raw metadata.
3. Prayer-time field names must preserve the Diyanet prayer-name meaning and must not be replaced by arbitrary short keys or English names.
4. Suggested normalized prayer fields:
   - `imsak`
   - `gunes`
   - `ogle`
   - `ikindi`
   - `aksam`
   - `yatsi`
   - optional: `kibleSaati`, if available and useful
   - optional: `hicriTarih`, if useful for UI
5. UI labels may localize these fields later, but the shared data contract should remain stable.
6. Main/current location should download yearly data.
7. One device/app installation can have:
   - 1 active main location
   - up to 10 simultaneously saved favorite locations
   - up to 30 unique downloaded locations per calendar year
8. The yearly 30-location limit is installation-based, not account-based, because there is no user login.
9. Yearly quota resets when the calendar year changes.
10. Old cached location data not used as main/favorite can be removed during yearly cleanup.

---

## Installation Identity

Because there is no login system, create an app installation identity.

### Requirements

1. Generate a random UUID on first app launch.
2. Store it locally and persistently.
3. Do not use Android advertising ID.
4. Do not use personally identifying data.
5. Use the installation ID only for local quota/accounting logic unless an explicit future analytics design is approved.
6. If the app is uninstalled, the installation ID may reset. This is acceptable for the zero-cost design.

---

## Data Publish Structure

Use a shared public path layout suitable for both mobile and desktop.

Recommended:

```text
haydi-namaza/
  prayer/
    diyanet/
      v1/
        manifest.json
        locations-tr.json
        2026/
          tr-42-konya-meram.json
          tr-42-konya-selcuklu.json
          tr-34-istanbul-fatih.json
```

Alternative ID-based filenames are acceptable if generated consistently:

```text
2026/
  17870.json
  17871.json
```

The file path must allow admin reporting scripts to map URL/path back to country/state/district/location.

---

## Publish JSON Format

Create a simplified yearly JSON per location.

Example shape:

```json
{
  "schemaVersion": 1,
  "source": "diyanet",
  "countryCode": "TR",
  "year": 2026,
  "locationId": "17870",
  "state": "Konya",
  "district": "Meram",
  "timezone": "Europe/Istanbul",
  "days": [
    {
      "date": "2026-01-01",
      "imsak": "06:32",
      "gunes": "07:59",
      "ogle": "12:58",
      "ikindi": "15:27",
      "aksam": "17:48",
      "yatsi": "19:10",
      "kibleSaati": "11:23",
      "hicriTarih": "12 Recep 1447"
    }
  ]
}
```

Rules:

1. Remove unused raw fields such as image URLs, long text duplicates, repeated API metadata, and fields not needed by the app.
2. Keep stable Diyanet prayer-name semantics.
3. Do not use short cryptic keys like `f`, `s`, `z`, `a`, `m`, `i`.
4. Ensure UTF-8 output.
5. Generate minified JSON for CDN publish.
6. Generate SHA256 checksums for all published files.
7. Include file size and hash information in `manifest.json`.

---

## Manifest Requirements

`manifest.json` must include:

1. schema version
2. dataset source
3. publish version
4. supported years
5. locations file URL/path
6. per-year file index
7. hash/checksum data
8. generated timestamp
9. compatibility notes for mobile and desktop

Example fields:

```json
{
  "schemaVersion": 1,
  "dataset": "prayer-diyanet",
  "publishVersion": "2026.1",
  "generatedAt": "2026-06-22T00:00:00Z",
  "years": [2026],
  "locationsPath": "locations-tr.json",
  "files": [
    {
      "year": 2026,
      "locationId": "17870",
      "path": "2026/tr-42-konya-meram.json",
      "sha256": "...",
      "bytes": 45123
    }
  ]
}
```

---

## Avkat Tasks

### AVKAT-01 — Inspect Current Raw Data

- Verify the raw Diyanet DateRange 2026 dataset.
- Confirm location count, day count, and missing records.
- Produce a summary report:
  - total states
  - total districts/locations
  - total yearly files
  - total daily records
  - missing or malformed records

### AVKAT-02 — Define Publish Schema

- Define the simplified JSON contract.
- Preserve Diyanet prayer-name semantics.
- Remove unused raw metadata.
- Decide optional fields:
  - `kibleSaati`
  - `hicriTarih`
  - any other necessary display-only fields

### AVKAT-03 — Build Publish Generator

Create a script that reads raw Avkat data and writes:

```text
publish/haydi-namaza/prayer/diyanet/v1/
```

Outputs:

- `manifest.json`
- `locations-tr.json`
- yearly location JSON files
- checksum report
- validation report

### AVKAT-04 — Validate Publish Output

Validation must check:

- 365/366 records per location/year
- required prayer fields present
- time format validity
- date order
- duplicate location IDs
- missing locations
- invalid UTF-8
- checksum generation

### AVKAT-05 — Keep Raw Data Immutable

- Do not modify raw Diyanet files.
- Publish output must be generated separately.
- Raw data remains the audit/source layer.

---

## Cloudflare Free Infrastructure Tasks

### CF-01 — Create Free-Tier Cloudflare Plan Checklist

Document exact setup steps for:

- Cloudflare account
- R2 bucket
- Standard storage only
- custom domain or public bucket access
- cache rules for static JSON
- no paid services enabled

### CF-02 — Upload Publish Files to R2

Upload only the generated publish folder.

Do not upload:

- raw Avkat files
- `.env`
- credentials
- private scripts
- repo metadata
- generated local zips

### CF-03 — Configure Cache Rules

Desired cache strategy:

- `manifest.json`: short cache
- `locations-tr.json`: medium cache
- yearly location JSON files: long cache / immutable version path

### CF-04 — Verify Zero-Cost Operation

Before use, verify:

- R2 storage under free quota
- R2 operation expectations under free quota
- no Workers/KV/D1 used
- no paid Cache Analytics required
- no paid Logpush required

If any paid requirement appears, stop and report.

---

## Admin Reporting Tasks

The app must not include extra analytics tracking.

Reporting should be done outside the app by an admin-side script.

### REPORT-01 — URL-Based Reporting Design

Design public file paths so each path maps to a known location.

Example:

```text
/prayer/diyanet/v1/2026/tr-42-konya-meram.json
```

This path can be mapped to:

- country
- state
- district
- location ID
- year

### REPORT-02 — GraphQL Analytics Script

Create an admin script that runs daily and queries Cloudflare Analytics API for yesterday's traffic.

The script should aggregate by URL/path and write to:

```text
admin_reports/cloudflare/prayer_downloads.sqlite
admin_reports/cloudflare/daily/yyyy-mm-dd.json
admin_reports/cloudflare/monthly/yyyy-mm.json
```

### REPORT-03 — Ranking Reports

Generate sorted reports:

- most downloaded locations daily
- most downloaded locations monthly
- most downloaded states monthly
- least downloaded locations
- total requests by year
- top 50 locations
- bottom 50 locations

### REPORT-04 — Cost-Safe Reporting

The reporting script must:

- run locally or manually first
- use very few API calls
- avoid Workers/KV/D1
- avoid paid Logpush
- avoid paid Cache Analytics
- stop if the API requires a paid plan

### REPORT-05 — Data Retention

Store only aggregate counts:

- date
- URL/path
- location ID
- state
- district
- request count
- cache hit/miss if available

Do not store:

- IP addresses
- user agents
- installation IDs
- device identifiers
- personal data

---

## M_HaydiNamaza Mobile Tasks

### MOBILE-01 — Add Diyanet Source Model

Add/confirm prayer source enum:

- `diyanet`
- existing Aladhan/calculation sources

Existing sources must not break.

### MOBILE-02 — Add Install ID

Generate and store installation UUID.

Use it only for local yearly quota tracking.

### MOBILE-03 — Add Local Diyanet Cache

Implement app-local storage for:

- manifest
- locations
- selected yearly location files
- download metadata
- yearly quota state

### MOBILE-04 — Add Quota Rules

Rules:

- 1 active main location
- 10 simultaneous favorite locations
- 30 unique downloaded locations per calendar year
- quota resets yearly
- cleanup removes unused old-year cached files

### MOBILE-05 — Add Diyanet Downloader

When user selects Diyanet source:

1. fetch manifest
2. fetch locations if needed
3. resolve selected location file
4. download yearly JSON
5. verify SHA256
6. store in local cache
7. serve prayer times from local cache

### MOBILE-06 — Connect Main Prayer Engine

Main screen, notifications, widget, adhan reminders, and prayer list must all read from the same repository/source layer.

### MOBILE-07 — Offline Behavior

If Diyanet data exists locally:

- app must work offline

If data does not exist locally:

- show a clear Turkish message
- do not silently fall back to another source unless user chooses it

### MOBILE-08 — UI Text

All user-facing text must be Turkish.

Technical identifiers and code should remain English ASCII.

---

## D_HaydiNamaza Desktop Compatibility Tasks

### DESKTOP-01 — Consume Same Published Contract

`D_HaydiNamaza` must later read the same manifest and yearly location JSON files.

### DESKTOP-02 — Share Parsing Rules

Use the same schema assumptions as mobile:

- stable Diyanet prayer field names
- yearly location files
- manifest + checksum
- local cache
- offline use

### DESKTOP-03 — Do Not Create a Separate Desktop-Only Format

If desktop needs a convenience layer, it must be derived from the shared publish JSON, not from a separate dataset.

---

## Security and Repository Rules

1. Do not commit `.env`.
2. Do not commit Cloudflare API tokens.
3. Do not commit account IDs or private credentials.
4. Do not commit raw user/device analytics.
5. Do not commit generated zips.
6. Keep private Avkat repo private.
7. Only publish sanitized JSON output to R2/CDN.
8. If any credential is accidentally included, stop and rotate it.

---

## Suggested Implementation Order

1. Avkat publish schema
2. Avkat publish generator
3. Avkat validation report
4. Cloudflare free-tier setup checklist
5. R2 test upload with 2–3 sample locations
6. Mobile Diyanet source model
7. Mobile downloader/cache/checksum
8. Mobile main-location yearly data flow
9. Mobile widget/notification integration
10. Admin GraphQL daily reporting script
11. Desktop reader using same publish contract

---

## Explicitly Deferred

These are not part of the free default implementation:

- Cloudflare Workers runtime gatekeeper
- KV/D1 quota database
- centralized per-installation quota enforcement
- paid Cache Analytics
- Logpush
- third-party paid database
- paid monitoring
- paid CDN plan
- paid server/VPS

They may only be discussed later if the user explicitly approves a paid/possibly paid architecture.
