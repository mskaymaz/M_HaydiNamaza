# HANDOFF.md

## AllApp local template sync (2026-07-15)

- AllApp remote: `https://github.com/mskaymaz/AllApp.git`, branch `main`.
- After fetch, `_external/AllAppRemote` local `main` and `origin/main` are aligned at `27a8788` (`0/0` ahead/behind).
- The root `AllApp/templates/shared_settings/` snapshot previously contained only v1; canonical v2 was synchronized locally with its schemas, examples, assets, scripts, and Flutter reference files.
- The two existing untracked AllAppRemote Hadith copies were preserved.
- Validation: v2 file lists match (`19/19`), JSON parse passed (`11` files), and `git diff --check` passed. Flutter validation was not run because app source was unchanged.

## Computer-side debug build checkpoint (2026-07-15)

- User ran `flutter build apk --debug` from the repository root.
- Result: successful; `build/app/outputs/flutter-apk/app-debug.apk` was generated.
- `audioplayers_android-5.2.1` reported deprecated `isSpeakerphoneOn` warnings only; no build failure.
- Phone validation may proceed using the user's separate debug/test flow. APK installation was not performed by Codex.

## Current status
2026-07-14 checkpoint: “Namaz Vaktinde Sessiz Kal” akışı eklendi. Hatırlatma ayarlarında ortak N/M değerleri (varsayılan 5/20 dakika) ve ana etkinleştirme kutusu bulunuyor; vakitler panelindeki çan ikonunun sağında 24 px SVG sessiz ikon, 36 px dokunma alanı ve 8 px kutu boşluğuyla gösteriliyor. Ana ayar kapalıyken ikon Ayarlar yönlendirmeli uyarı verir; açıkken her vakit ayrı ayrı etkinleştirilir. Android alarm akışı sessize alma başlangıç/bitiş olaylarını uygulama kapalıyken de çalıştırıp önceki zil modu ve bildirim filtresini geri yüklemeyi deniyor. Android Notification Policy Access ekranı ana ayar etkinleştirilirken açılır.
Validation in this checkpoint: `git diff --check` completed without whitespace errors. `dart format` was attempted but timed out; `flutter analyze` and `flutter build apk --debug` were not run. Before phone testing, first run `flutter build apk --debug` and confirm it succeeds; APK installation is not part of this checkpoint.

2026-06-11 checkpoint: UI/prayer-time engine stabilization started. Diyanet/AwqatSalah access remains unresolved, so the current direction is calculation-based release stabilization with honest source labels instead of blocking all work on official access.
Aladhan method selection now routes directly through the Aladhan fetch path; Türkiye method labels no longer imply official Diyanet data. Default voice reminder Turkish text and Arabic country label were cleaned.
AllApp approved daily content publish artifacts were committed and pushed to `https://github.com/mskaymaz/AllApp.git` branch `main` at commit `39fe32b`.
Validation reported by user:
- `flutter test test/app/prayer_service_source_labels_test.dart`: `00:08 +3: All tests passed!`
- `flutter analyze`: `No issues found! (ran in 40.7s)`

R260609_1528 commit hazırlığı: Python arayüzü üzerinden ayet ve hadis eklemeleri yapılacak; yerel approved JSON yapısı, `onay.py`, `incele.py`, bulk ekleme araçları ve AllApp publish/push yardımcıları bu akışı destekleyecek şekilde güncellendi.
Daily content review tool now has approved-only mobile preview for ayah/hadith/esma, unified archive root `assets/data/daily_content/archive/`, and unified approved root `assets/data/daily_content/approved/`.
Current approved counts are `ayah=1438`, `hadith=438`, `esma/sifat=381` (`esma=99`, `sifat=282`).
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
Continue main screen UI, settings, qibla, daily content, and prayer-time engine cleanup from this checkpoint.
Continue ayah/hadith/esma-sifat manual review from approved/runtime payloads when content work resumes.

## Important blockers
- Official Diyanet/AwqatSalah access contract remains unresolved; current release path should use calculation-based source labeling unless a new official data decision is made.

## UI / engine stabilization checkpoint (2026-06-11)
- Scope:
  - Bound explicit `aladhan` calculation method to the Aladhan API path.
  - Kept `turkey` on Turkey calculation parameters while removing official-Diyanet wording from visible labels.
  - Marked `diyanet_tabanli` as experimental in settings labels.
  - Fixed default voice reminder Turkish text.
  - Fixed Arabic `locationCountryLabel`.
- Changed files:
  - `lib/app/prayer_service.dart`
  - `lib/app/prayer_calculation_parameters_factory.dart`
  - `lib/core/config/config_registry.dart`
  - `lib/app/reminder_text_settings_storage.dart`
  - `lib/presentation/settings/calculation_method_screen.dart`
  - `lib/presentation/settings/settings_ui_mappers.dart`
  - `lib/l10n/app_tr.arb`
  - `lib/l10n/app_en.arb`
  - `lib/l10n/app_ar.arb`
  - `lib/l10n/app_localizations.dart`
  - `lib/l10n/app_localizations_tr.dart`
  - `lib/l10n/app_localizations_en.dart`
  - `lib/l10n/app_localizations_ar.dart`
  - `test/app/prayer_service_source_labels_test.dart`
- Validation:
  - User ran `flutter test test/app/prayer_service_source_labels_test.dart`: `00:08 +3: All tests passed!`
  - User ran `flutter analyze`: `No issues found! (ran in 40.7s)`

## AllApp publish push (2026-06-11)
- Target repo/branch: `https://github.com/mskaymaz/AllApp.git` / `main`.
- Remote commit: `39fe32b` (`daily-content: sync approved publish payloads`).
- Published files:
  - `data/daily_content/v1/manifest.json`
  - `data/daily_content/v1/publish/ayahs.v1.approved.json`
  - `data/daily_content/v1/publish/hadiths.v1.approved.json`
  - `data/daily_content/v1/publish/esmaul_husna.v1.approved.json`

## Esma/Sifat approved verification (2026-06-10)
- Rebuilt local approved Esma/Sifat payload from source JSON files:
  - `assets/data/daily_content/approved/esmaul_husna.v1.approved.json`
  - Total approved records: `381` (`esma=99`, `sifat=282`).
- Local AllApp publish artifact added/updated without regenerating ayah/hadith publish files:
  - `_external/AllAppRemote/data/daily_content/v1/publish/esmaul_husna.v1.approved.json`
  - `_external/AllAppRemote/data/daily_content/v1/manifest.json`
- Validation:
  - local approved payload: `records=381`, `approved=381`, `esma=99`, `sifat=282`
  - local AllApp publish payload: `records=381`, `approved=381`, `esma=99`, `sifat=282`
  - manifest `publish_files.esmas.record_count=381`
- AllApp remote push was not run in this step.

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

## Esma/Sıfat approved payload update (2026-06-09)
- Source files checked:
  - `docs/EsmaulHusna/Esma_ar_tr_en_99.json`: `99` records, duplicate ids `0`, missing required AR/TR/EN fields `0`.
  - `docs/EsmaulHusna/esma_sifat_282.json`: `282` records, duplicate ids `0`, missing required AR/TR/EN fields `0`.
- Local approved payload generated:
  - `assets/data/daily_content/approved/esmaul_husna.v1.approved.json`
  - Total records: `381` (`esma=99`, `sifat=282`).
  - `assets/data/daily_content/approved/sequence.v1.json` now includes `esma_order_ids` and `sifat_order_ids`.
- App runtime:
  - Daily content remote manifest now requires `publish_files.esmas`.
  - App falls back to local approved assets if remote manifest/payload is missing.
  - Home daily panel order is `Ayet -> Hadis -> Esma -> Sıfat`.
- AllApp local publish artifacts generated under `_external/AllAppRemote/data/daily_content/v1/`:
  - `manifest.json`
  - `publish/ayahs.v1.approved.json`
  - `publish/hadiths.v1.approved.json`
  - `publish/esmaul_husna.v1.approved.json`
- AllApp remote push was not run in this step.

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

## Shared Settings Template Alignment (2026-07-14)

- AllApp `templates/shared_settings/v2/` is now the canonical shared-settings contract/reference.
- v2 documents the four standard sections: Hakkımızda, Uygulama Bilgileri ve Güncelleme, Uygulamalarımız, Destek Olabilirsiniz.
- Added current config, contact, about, catalog, and update-manifest schemas plus example payloads.
- The root `AllApp/templates/shared_settings/v1/` copy is marked as legacy; it is not the starting point for new apps.
- Haydi Namaza config now uses `Haydi Namaza` as the app name, supports config-driven support actions, and falls back to the local update manifest when the remote manifest cannot be read.
- `dart format` timed out in the local environment; `git diff --check` passed. User should run `flutter analyze` before device testing.
- User validation (2026-07-14): `flutter analyze` completed successfully; `No issues found!` (54.4s). `flutter pub get` also completed successfully; 41 packages have newer incompatible versions, which is informational only.

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

