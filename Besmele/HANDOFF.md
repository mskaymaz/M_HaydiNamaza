# HANDOFF.md

## Current status
R260609_1528 commit hazırlığı: Python arayüzü üzerinden ayet ve hadis eklemeleri yapılacak; yerel approved JSON yapısı, `onay.py`, `incele.py`, bulk ekleme araçları ve AllApp publish/push yardımcıları bu akışı destekleyecek şekilde güncellendi.
Daily content review tool now has approved-only mobile preview for ayah/hadith/esma, unified archive root `assets/data/daily_content/archive/`, and unified approved root `assets/data/daily_content/approved/`.
Current approved counts are `ayah=1438`, `hadith=438`, `esma=99`.
TASK-03 is closed and pushed on `main`.
TASK-00 is completed on 2026-05-10 with documented exceptions.
TASK-04A is closed (checkpoints completed; orchestration-safe extraction scope finalized).
TASK-04B documentation scope is closed, including official Diyanet/AwqatSalah API source strategy notes.
TASK-05 checkpoints 1-14 are synchronized with `Besmele/TASKS.md` for current scope.
TASK-05 content target closure is recorded (`approved` counts: ayah=424, hadith=550).
TASK-05B publish runbook documentation is completed, and AllApp public publish sync target is configured.
TASK-07 shared settings modules are completed with config-driven integration.
TASK-08 AllApp shared settings template/contracts are completed for current scope.
TASK-06 is completed with location-based qibla bearing + sensor fallback + bearing validation tests.
TASK-10 is completed with storage fallback/recovery hardening and log-safe non-fatal reporting.
TASK-11 is completed and pushed in current flow.
TASK-12 release-readiness documentation/checklist outputs are completed.
Ayah/hadith data reset was executed on 2026-06-02; old lists, publish payloads, archives, and source folders were removed, and a new clean seed structure was created.

## Next action
Continue ayah/hadith manual review from `assets/data/daily_content/archive/`, rebuild approved runtime payloads under `assets/data/daily_content/approved/`, then sync AllApp publish artifacts.

## Important blockers
- Production release remains blocked until official Diyanet/AwqatSalah access contract (auth/token + usage/release decision) is explicitly cleared.

## AllApp daily content publish sync (2026-06-09)
- Target repo/branch: `https://github.com/mskaymaz/AllApp.git` / `main`.
- Remote commit: `12399cd` (`daily-content: sync local approved publish v1`).
- Published files:
  - `data/daily_content/v1/manifest.json`
  - `data/daily_content/v1/publish/ayahs.v1.approved.json`
  - `data/daily_content/v1/publish/hadiths.v1.approved.json`
- Remote raw validation:
  - `manifest=local-approved-20260609_074542`
  - `ayah_count=37`
  - `hadith_count=8`

## Bulk hadith local approval update (2026-06-09)
- Requested hadith numbers: `436`.
- Already approved before run: `6` (`1729`, `1218`, `153`, `381`, `1075`, `1535`).
- Newly added to local approved payload: `430`.
- Local approved hadith total after run: `438`.
- Validation:
  - requested missing from approved: `0`
  - duplicate hadith numbers in approved: `0`
  - blank AR/TR/EN text records: `0`
- AllApp remote publish was not pushed after this bulk local approval update.

## Bulk ayah local approval update (2026-06-09)
- Requested ayah refs: `118`.
- Already covered by approved records before run: `28`.
- Newly added to local approved payload: `90`.
- Local approved ayah total after run: `127`.
- Validation:
  - requested refs missing from approved coverage: `0`
  - duplicate exact refs in approved: `0`
  - blank AR/TR/EN text records: `0`
- AllApp remote publish was not pushed after this bulk local approval update.

## Bulk ayah local approval update 2 (2026-06-09)
- Requested ayah refs: `1400`.
- Already covered by approved records before run: `89`.
- Newly added to local approved payload: `1311`.
- Local approved ayah total after run: `1438`.
- Validation:
  - requested refs missing from approved coverage: `0`
  - duplicate exact refs in approved: `0`
  - blank AR/TR/EN text records: `0`
- AllApp remote publish was not pushed after this bulk local approval update.

## Final stabilization checkpoint (2026-05-14)
- Scope:
  - Documentation-only closure sync for TASK-05/TASK-05B completion records and current release blockers.
- Changed files:
  - `README.md`
  - `Besmele/TASKS.md`
  - `docs/architecture/DAILY_CONTENT_PUBLISH_RUNBOOK.md`
  - `docs/architecture/PRAYER_TIMES_DATA_SOURCE_STRATEGY.md`
  - `STATE.md`
  - `Besmele/HANDOFF.md`
  - `Besmele/WORKBOARD.md`
- Validation:
  - `flutter analyze` was not run in this step by scope rule.

## TASK-07 and TASK-08 closure update (2026-05-14)
- Scope:
  - Reusable shared-settings template extraction from M_RekatSay to AllApp and integration into M_HaydiNamaza settings page.
- Changed files:
  - `AllApp/templates/shared_settings/v1/README.md`
  - `AllApp/templates/shared_settings/v1/schemas/app_settings.schema.json`
  - `AllApp/templates/shared_settings/v1/schemas/app_catalog.schema.json`
  - `AllApp/templates/shared_settings/v1/schemas/update_manifest.schema.json`
  - `AllApp/templates/shared_settings/v1/schemas/support_contact.schema.json`
  - `AllApp/templates/shared_settings/v1/schemas/about.schema.json`
  - `AllApp/templates/shared_settings/v1/examples/shared_settings.app.sample.json`
  - `AllApp/templates/shared_settings/v1/examples/app_catalog.sample.json`
  - `AllApp/templates/shared_settings/v1/examples/update_manifest.sample.json`
  - `lib/features/shared_settings/shared_settings_models.dart`
  - `lib/features/shared_settings/shared_settings_parser.dart`
  - `lib/features/shared_settings/shared_settings_remote_client.dart`
  - `lib/features/shared_settings/shared_settings_app_config.dart`
  - `lib/presentation/settings/widgets/settings_shared_modules_group.dart`
  - `lib/presentation/settings/settings_screen.dart`
  - `assets/data/shared_settings/app_catalog.local.json`
  - `assets/data/shared_settings/update_manifest.local.json`
  - `test/features/shared_settings/shared_settings_parser_test.dart`
  - `pubspec.yaml`
  - `Besmele/TASKS.md`
  - `STATE.md`
  - `Besmele/HANDOFF.md`
  - `Besmele/WORKBOARD.md`
- Validation:
  - `flutter analyze` was not run in this step by scope rule.

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

## TASK-09 UI/UX Professionalization (2026-06-09)

- Scope:
  - Daily content panel: replaced stacked multi-language text layout with single-language tabbed view
  - State panels: added icons, better spacing, polished card layouts for missing-location, invalid-location, and prayer-times-unavailable states
  - Visual hierarchy: clarified content structure with consistent spacing and typography
- Changed files:
  - `lib/presentation/home/widgets/home_daily_content_panel.dart`
  - `lib/presentation/home/widgets/home_state_panels.dart`
  - `Besmele/TASKS.md`
  - `STATE.md`
  - `Besmele/HANDOFF.md`
- Validation:
  - flutter analyze was not run in this step by scope rule.
  - Note: original note "arayüz sıkıntılı, metinler yukarıdan aşağıya akıyor" addressed via single-language tab display.

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

