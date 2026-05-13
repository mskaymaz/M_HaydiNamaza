# HANDOFF.md

## Current status
TASK-03 is closed and pushed on `main`.
TASK-00 is completed on 2026-05-10 with documented exceptions.
TASK-04A is closed (checkpoints completed; orchestration-safe extraction scope finalized).
TASK-04B documentation scope is closed, including official Diyanet/AwqatSalah API source strategy notes.
TASK-05 checkpoints 1-14 are synchronized with `Besmele/TASKS.md` for current scope.
TASK-06 is completed with location-based qibla bearing + sensor fallback + bearing validation tests.
TASK-10 is completed with storage fallback/recovery hardening and log-safe non-fatal reporting.
TASK-11 is completed and pushed in current flow.
TASK-12 release-readiness documentation/checklist outputs are completed.
Ayah/hadith data work is completed for current scope (approved sample set + draft pool workflow records).

## Next action
Wait for explicit start instruction before TASK-07.

## Important blockers
- Final release remains blocked until explicit official prayer-time source/release decision is cleared.
- Future curated 400 + 400 approved ayah/hadith dataset is still pending as a later content phase.

## TASK-12 closure update (2026-05-13)
- Scope:
  - Release readiness documentation/checklist outputs (README rewrite, privacy note, data-source transparency note, release checklist, build instructions, and repository safety verification).
- Changed files:
  - `README.md`
  - `Besmele/TASKS.md`
  - `STATE.md`
  - `Besmele/HANDOFF.md`
- Validation:
  - `flutter analyze` was not run in this step by scope rule.
- Release gate:
  - Final release blocker remains active until official prayer-time source/release decision is explicitly cleared.

## TASK-06 closure update (2026-05-13)
- Scope:
  - Qibla direction engine upgrade with location-based mode, sensor fallback mode, user guidance, and bearing validation tests.
- Changed files:
  - `lib/features/qibla/qibla_constants.dart`
  - `lib/features/qibla/qibla_bearing_calculator.dart`
  - `lib/presentation/home/widgets/home_qibla_screen.dart`
  - `test/features/qibla/qibla_bearing_calculator_test.dart`
  - `Besmele/TASKS.md`
  - `STATE.md`
  - `Besmele/HANDOFF.md`
- Validation:
  - `flutter analyze` was not run in this step by scope rule.

## TASK-10 closure update (2026-05-13)
- Scope:
  - Persistence/error/offline safety hardening for local storage decode/write failures and location permission recovery path.
- Changed files:
  - `lib/app/runtime_monitor.dart`
  - `lib/app/prayer_daily_cache_repository.dart`
  - `lib/app/reminder_trigger_storage.dart`
  - `lib/app/prayer_row_settings_storage.dart`
  - `lib/app/custom_prayer_storage.dart`
  - `lib/features/daily_content/daily_content_state_repository.dart`
  - `lib/features/daily_content/daily_content_service.dart`
  - `lib/presentation/settings/location_screen.dart`
  - `Besmele/TASKS.md`
  - `STATE.md`
  - `Besmele/HANDOFF.md`
- Validation:
  - `flutter analyze` was not run in this step by scope rule.

## TASK-00 audit notes (2026-05-10)
- Branch `upgrade/advanced-cleanup` is treated as obsolete for now because cleanup work already landed on `main` and `origin/main` is aligned.
- Duplicate instruction roots are absent at repo root: `BesmeleGenel`, `ContextKit`, `core`, `rules`, `flows`, `plans`, `sessions`, `oturumlar`, `hooks`, `optional`.
- Archived instruction material exists in `_archive_instruction_old_20260509_131932/` and `_archive_instruction_old_20260509_132105/`.
- `flutter analyze` was not run in this audit; user-reported baseline remains `No issues found!`.
- `flutter pub get` was executed successfully by user on 2026-05-10 (`Got dependencies!`).
- Newer package versions are available but incompatible with current dependency constraints; this is not a TASK-00 blocker.
- Root `tools/` remains intentionally active because it contains utility scripts, not instruction-only duplicates.

## Do not forget
- The app must stay working during refactors.
- Large files must be split gradually.
- Shared settings must be reusable across MSK Labs apps.

## TASK-04A checkpoint (2026-05-11)
- Changed files:
  - `lib/app/prayer_calculation_parameters_factory.dart`
  - `lib/app/prayer_service.dart`
  - `Besmele/TASKS.md`
  - `Besmele/HANDOFF.md`
- Validation:
  - `flutter analyze` was not run in this step by scope rule.

## TASK-04A checkpoint 2 (2026-05-11)
- Changed files:
  - `lib/app/prayer_daily_cache_repository.dart`
  - `lib/app/prayer_service.dart`
  - `Besmele/TASKS.md`
  - `Besmele/HANDOFF.md`
- Validation:
  - `flutter analyze` was not run in this step by scope rule.

## TASK-04A checkpoint 3 (2026-05-11)
- Changed files:
  - `lib/app/diyanet_location_id_resolver.dart`
  - `lib/app/prayer_service.dart`
  - `Besmele/TASKS.md`
  - `Besmele/HANDOFF.md`
- Validation:
  - `flutter analyze` was not run in this step by scope rule.

## TASK-04A checkpoint 4 (2026-05-11)
- Changed files:
  - `lib/app/diyanet_prayer_times_client.dart`
  - `lib/app/prayer_service.dart`
  - `Besmele/TASKS.md`
  - `Besmele/HANDOFF.md`
- Validation:
  - `flutter analyze` was not run in this step by scope rule.

## TASK-04B source strategy closure update (2026-05-13)
- Scope:
  - Documentation-only source strategy update for official Diyanet prayer-time API discovery.
- Recorded official sources:
  - `https://awqatsalah.diyanet.gov.tr/index.html`
  - `https://awqatsalah.diyanet.gov.tr/scalar/`
  - `https://github.com/DinIsleriYuksekKurulu/AwqatSalah`
- Recorded notes:
  - API adı: `AwqatSalah / Diyanet Namaz Vakti API`.
  - OpenAPI sayfasında `Diyanet Namaz Vakti API - Version 1` ve OpenAPI JSON indirme bilgisi bulunur.
  - Auth/token başvuru süreci gerekebilir; repo içine gerçek token/credential eklenmez.
  - Resmi sayfada Auth/Login, RefreshToken, Place/Countries, Place/States, Place/Cities, CityDetail, Daily, Weekly, Monthly, Eid, Ramadan, DateRange endpointleri listelenir.
- Validation:
  - `flutter analyze` was not run in this step by scope rule.

