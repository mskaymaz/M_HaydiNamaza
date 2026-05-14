# Daily Content Publish Runbook

Purpose: generate approved ayah/hadith publish payloads in private repo, then sync public AllApp artifacts.

## Scope
- Private canonical sources:
  - `Besmele/data/daily_panel/archive/base_release_2026-05-14/legacy_files/ayahs_draft_Edit.json`
  - `Besmele/data/daily_panel/archive/base_release_2026-05-14/legacy_files/hadiths_draft_DiyanetUnified_v2.json`
- Private publish outputs:
  - `Besmele/data/daily_panel/publish/ayahs.v1.approved.json`
  - `Besmele/data/daily_panel/publish/hadiths.v1.approved.json`
  - `assets/data/daily_content/approved/ayahs.v1.approved.json`
  - `assets/data/daily_content/approved/hadiths.v1.approved.json`
- Public distribution contract root:
  - `AllApp/data/daily_content/v1/`

## Step 1 - Generate private publish payloads
Run from repo root:

```powershell
python tools/daily_content/generate_publish_payloads.py
```

Expected:
- Script prints `publish payloads generated`.
- `Besmele/data/daily_panel/archive/base_release_2026-05-14/publish_generation/publish_manifest.json` is refreshed.

## Step 2 - Generate AllApp monthly packs + manifest
Run from repo root:

```powershell
python tools/daily_content/generate_allapp_monthly_packs.py
```

Expected:
- Script prints `allapp monthly packs generated`.
- Files are refreshed under:
  - `AllApp/data/daily_content/v1/publish/`
  - `AllApp/data/daily_content/v1/monthly/`
  - `AllApp/data/daily_content/v1/manifest.json`

## Step 3 - Verify local outputs
Minimum checks:

```powershell
git status --short
Get-Content AllApp/data/daily_content/v1/manifest.json -TotalCount 80
```

Verify:
- `content_version` and `generated_at_utc` are current.
- Monthly files exist for expected range.
- Publish payload paths and checksums are present.

## Step 4 - Sync to public repo
- Keep this repo as canonical source of truth.
- Copy/sync `AllApp/data/daily_content/v1/` artifacts into the public distribution repo.
- Commit in public repo with message format:
  - `daily-content: publish v1 <YYYY-MM-DD>`
- Tag optional release marker if needed.

## Step 5 - Post-sync validation
- Confirm app remote fetch URL serves updated manifest and publish files.
- Keep private archive snapshots in this repo for audit trail.
