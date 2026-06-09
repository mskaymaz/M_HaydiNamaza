# M_HaydiNamaza — Advanced Upgrade Tasks

This is the canonical task file. Do not create another competing `Tasks.md`, `WORKBOARD-1.md`, or task folder unless the user explicitly requests it.

## Global rules
- Work in small steps.
- Keep the app buildable after each step.
- Prefer files under 400 lines; 600 lines only when unavoidable.
- UI must not hold business logic.
- Services must not hold widget logic.
- User-facing text must be Turkish.
- Code identifiers should be English ASCII.
- Do not finalize release before official prayer-time data strategy is decided.

---

## TASK-00 - Baseline Safety and Instruction Cleanup

Goal: make the repo understandable before code changes.

- [x] Create branch `upgrade/advanced-cleanup` (documented exception: obsolete on current `main` flow).
- [x] Confirm current app baseline with `flutter pub get`.
- [x] Run `flutter analyze` and save result summary in `Besmele/HANDOFF.md`.
- [x] Archive old duplicated instruction files into `_archive_instruction_old/<timestamp>/`.
- [x] Keep only root `AGENTS.md`, `CORE.md`, `STATE.md`, and `Besmele/` as active instruction system.
- [x] Remove active duplicate folders from instruction flow: `BesmeleGenel`, `ContextKit`, root `core/rules/flows/plans/sessions/oturumlar/hooks/optional/tools` if they only contain AI instruction material.
- [x] Keep old files in archive, not permanent delete.
- [x] Verify Codex/Copilot startup path is clear.

TASK-00 audit notes (2026-05-10):
- Branch exception: `upgrade/advanced-cleanup` was not created because current completed cleanup/decomposition work is already on `main` and pushed (`main` == `origin/main`, latest commit `2737174`).
- Baseline command confirmation: `flutter pub get` executed by user on 2026-05-10. Result: `Got dependencies!` with note `26 packages have newer versions incompatible with dependency constraints`.
- Baseline command note: `flutter analyze` was not executed in this audit by scope rule; user-reported result is `No issues found!` and recorded in `Besmele/HANDOFF.md`.
- Archive verification: old instruction material is present in `_archive_instruction_old_20260509_131932/` and `_archive_instruction_old_20260509_132105/`.
- Duplicate folder verification: `BesmeleGenel`, `ContextKit`, `core`, `rules`, `flows`, `plans`, `sessions`, `oturumlar`, `hooks`, `optional` are absent at repo root.
- Utility exception: root `tools/` is kept active because it contains utility scripts (`flutter.ps1`, `run_m.ps1`, `golden_test_runner.dart`), not instruction-only duplicates.

Acceptance:
- One active instruction hierarchy remains.
- Old documents are recoverable from archive.
- No app code changed.

---

## TASK-01 — Current Architecture Map

Goal: understand the app before refactoring.

- [x] Create `docs/architecture/CURRENT_ARCHITECTURE.md`.
- [x] List main app entry points.
- [x] List current feature folders.
- [x] List all files over 600 lines.
- [x] Identify UI files that contain business logic.
- [x] Identify services that mix unrelated responsibilities.
- [x] Identify prayer-time, qibla, settings, notification, location, and content flows.
- [x] Record safe refactor order.

Acceptance:
- Refactor order is documented.
- No code behavior changed.

---

## TASK-02 — Target Architecture Skeleton

Goal: create structure without moving risky behavior yet.

- [x] Create or align `lib/app/` for app shell, config, theme, routing.
- [x] Create or align `lib/core/` for shared constants, storage, errors, logging, platform utilities, common widgets.
- [x] Create or align `lib/features/prayer_times/`.
- [x] Create or align `lib/features/qibla/`.
- [x] Create or align `lib/features/daily_content/`.
- [x] Create or align `lib/features/shared_settings/`.
- [x] Create or align `lib/features/location/`.
- [x] Create or align `lib/features/notifications/`.
- [x] Add barrel files only if they reduce import noise.

Acceptance:
- New folders exist.
- No functional behavior changed.
- `flutter analyze` does not get worse because of empty/unused broken files.

---

## TASK-03 — Large File Decomposition

Goal: split oversized files safely.

- [x] Split `home_screen.dart` with safe layout/panel/helper/model extraction.
- [x] Split `settings_screen.dart` into focused settings cards/sections.
- [x] Split `location_screen.dart` with safe UI/helper/model extraction.
- [x] Move pure UI widgets first.
- [x] Documented exception recorded: deeper HomeController/ViewModel/ReminderEngine extraction is deferred to a future dedicated architecture task (not TASK-03) to avoid high-risk behavior changes.
- [x] Keep each step compile-safe.
- [x] Documented exception recorded: no dedicated dead-code deletion pass was executed in `TASK-03`; cleanup is deferred to a later validated phase.

### TASK-03 Final Audit and Closure (2026-05-10)

Status: Closed after safe decomposition checkpoints and documented exception handling.

- Final known line counts:
  - home_screen.dart: ~1316
  - settings_screen.dart: ~594
  - location_screen.dart: ~596
  - prayer_service.dart: ~581
- Documented >600 line exceptions:
  - home_screen.dart remains above 600 because it still owns protected parent orchestration, lifecycle, reminders, dialogs, storage, notification/audio/vibration, and location/prayer coordination flows.
- settings_screen.dart is reduced below 600 lines (~594) in current state.
- location_screen.dart is reduced below 600 lines (~596) in current state.
- prayer_service.dart is reduced below 600 lines (~581) in current state.
- Final closure note:
  - Pure UI/widgets/helpers/models were extracted in safe phases.
  - High-risk parent orchestration intentionally stayed in home_screen.dart.
  - No behavior change intended.
  - Deeper HomeController/ViewModel/ReminderEngine extraction is deferred to a future dedicated architecture task, not TASK-03.

### TASK-03A � settings_screen.dart UI decomposition

- [x] Extract settings section panel/header helpers.
- [x] Extract reminder field/toggle helpers.
- [x] Extract color action/reset helpers.
- [x] Extract reminder text settings mapper/snapshot helpers.
- [x] Extract pure formatter/helper functions.
- [x] Extract settings color sections group.
- [x] Extract settings reminder options group.
- [x] Extract settings reminder sections group.
- [x] Extract settings top settings section.
- [x] Stop tiny UI extraction to avoid over-fragmentation.
- [x] Audit settings orchestration/load-save/service separation.
- [x] Continuation checkpoint: extracted internal color dialog UI widgets (`ColorSpectrum`, `HueStrip`) and moved `FlashingReminderPreview` into settings widgets files; orchestration stayed in `settings_screen.dart`.

### TASK-03B � location_screen.dart safe UI/helper extraction checkpoint

- [x] Extract location name formatting helpers.
- [x] Extract location add-favorite button.
- [x] Extract location selection composer.
- [x] Extract generic dropdown item builder.
- [x] Stop further micro UI/helper extraction to avoid over-fragmentation.
- [x] Audit location orchestration/service/repository boundaries.
- [x] Continuation checkpoint: extracted pure location parser/normalization helpers to `location_data_parsers.dart`, favorite label helpers to `location_label_helpers.dart`, and `_DiyanetItem` model to `location_models.dart`; orchestration/state/network/navigation remained in `location_screen.dart`.
- Continuation checkpoint: tiny safe line compaction only (no behavior change, no orchestration move).
- location_screen.dart reduced below 600 in this pass (~596 lines).

### TASK-03C � home_screen.dart first presentational extraction checkpoint

Status: Final audit completed with documented exceptions; safe decomposition checkpoint closed without behavior change.

Completed:
- Extracted only self-contained presentational UI blocks from `home_screen.dart`.
- Added/updated `lib/presentation/home/widgets/home_presentational_widgets.dart`.
- Extracted:
  - `HomeReminderChip`
  - `HomeIconToggle`
  - `HomeActiveReminderPanel`
  - `HomeDrawerHandlePainter`
- Kept parent state, callbacks, orchestration, navigation, dialogs, snackbars, mounted checks, and business logic inside `home_screen.dart`.
- No behavior change intended.
- Local validation completed by user:
  - `flutter analyze`
  - Result: `No issues found!`
- `home_screen.dart` line count after checkpoint: `2754`.
- Continuation checkpoint:
  - `_TopPanel` extracted to `lib/presentation/home/widgets/home_top_panel.dart`.
  - Renamed `_TopPanel` to `HomeTopPanel`.
  - No behavior change intended.
  - Historical note: this was an in-progress checkpoint state.
- Continuation checkpoint:
  - Fallback/state panels extracted to `lib/presentation/home/widgets/home_state_panels.dart`.
  - No behavior change intended.
  - Historical note: this was an in-progress checkpoint state.
- Continuation checkpoint:
  - `_PrayerList` extracted to `lib/presentation/home/widgets/home_prayer_list.dart`.
  - `_PrayerItem` renamed to `HomePrayerListItem`.
  - `_measureTextWidth` moved with the widget.
  - No behavior change intended.
  - Historical note: this was an in-progress checkpoint state.
- Continuation checkpoint:
  - `_QiblaScreen` extracted to `lib/presentation/home/widgets/home_qibla_screen.dart`.
  - Renamed `_QiblaScreen` to `HomeQiblaScreen`.
  - Qibla calculation helpers kept inside extracted screen.
  - No behavior change intended.
  - Historical note: this was an in-progress checkpoint state.
- Continuation checkpoint:
  - Pure date/text/hijri helpers extracted to `lib/presentation/home/home_date_text_helpers.dart`.
  - No behavior change intended.
  - Historical note: this was an in-progress checkpoint state.
- Final note for now:
  - TASK-03C `home_screen.dart` decomposition checkpoint is sufficiently completed for now.
  - `home_screen.dart` reduced to `1920` lines.
  - Further extraction is intentionally paused.
  - Reason: remaining large sections are protected high-coupling parent orchestration/state/dialog/storage/notification/location/prayer-time/reminder logic.
  - Type/data block is not extracted now because benefit is modest versus visibility/API churn.
  - No behavior change intended.
  - Historical note: final TASK-03 status is updated in the final audit section above.
  - TTS experiment note: English/Arabic voice picker, voice scan dialog, and per-language read actions were prototyped in settings and daily-content surfaces, then rolled back to keep the stable Turkish-only read path.
  - Technical reason: device TTS voice identity can drift across engines/updates; retaining explicit non-Turkish read surfaces without a pinned voice contract created unstable UX.
- Continuation checkpoint:
  - Bottom private model/type block extracted to `lib/presentation/home/home_models.dart` via `part/part of`.
  - Moved: `_HomeData`, `_PrayerRowSettings`, `_CustomPrayerDraft`, `_CustomPrayerTimeMode`, `_CustomPrayerTimeRule`, `_ReminderStage`, `_PrayerNext`.
  - No behavior change intended.
  - Historical note: this was an in-progress checkpoint state.
- Continuation checkpoint:
  - Pure prayer-time helper methods extracted to `lib/presentation/home/home_prayer_time_helpers.dart` via `part/part of`.
  - Moved: `_activePrayer`, `_nextPrayer`, `_formatCountdown`, `_atToday`, `_prayerTimeFor`, `_prayerLabel`.
  - No behavior change intended.
  - Historical note: this was an in-progress checkpoint state.
- Continuation checkpoint:
  - Pure custom-prayer time resolve helper extracted to `lib/presentation/home/home_custom_time_helpers.dart` via `part/part of`.
  - Moved: `_resolveCustomPrayerTime`.
  - `openCustomTimeEditor` and bottom-sheet/state orchestration kept in `home_screen.dart`.
  - No behavior change intended.
  - Historical note: this was an in-progress checkpoint state.
- Continuation checkpoint:
  - Pure drawer layout calculation helper extracted to `lib/presentation/home/home_drawer_layout_helpers.dart` via `part/part of`.
  - Moved: pure drawer size/position constants and `_computeDrawerLayout`.
  - Gesture callbacks and drawer `setState` orchestration kept in `home_screen.dart`.
  - No behavior change intended.
  - Historical note: this was an in-progress checkpoint state.
- Final TASK-03C sweep checkpoint:
  - Custom prayer time editor bottom-sheet UI extracted to `lib/presentation/home/home_custom_time_editor_sheet.dart` via `part/part of`.
  - `showModalBottomSheet`, parent `setState`, and `_persistCustomPrayerRows` orchestration stayed in `home_screen.dart`.
  - Drawer handle band extraction was intentionally skipped in this sweep to avoid unnecessary orchestration coupling.
  - No behavior change intended.

### TASK-03D - prayer_service.dart safe helper extraction checkpoint (2026-05-10)

- Scope:
  - One safe decomposition phase for lib/app/prayer_service.dart without behavior changes.
- Extracted to new file:
  - lib/app/prayer_service_pure_helpers.dart
  - DiyanetIds value class
  - Pure clock-time parser helper
  - Pure minute-offset helper
  - Pure Diyanet list ID lookup helper
  - Pure location-name normalization helper
  - Pure HH:mm formatting helper
- Updated in prayer_service.dart:
  - Replaced duplicated inline parse/offset/name/format logic with helper calls.
  - Kept service API and async orchestration unchanged.
- Intentionally kept in prayer_service.dart (risk-managed):
  - calculateToday public flow
  - Diyanet/Aladhan request sequencing and fallback order
  - Cache read/write side effects
  - Error handling and null-return semantics
  - Prayer-time assembly behavior (PrayerTimes.fromTimings call flow)
- Result:
  - prayer_service.dart reduced to ~581 lines.
  - No behavior change intended.

Notes:
- TASK-03 safe decomposition closure is recorded in this file with documented exceptions.
- Do not move service/storage/notification/location/prayer-time calculation logic.
- Do not move Navigator/SnackBar/Dialog/setState/mounted flows.
- Avoid tiny low-value extractions.

Acceptance:
- No file remains above 600 lines unless documented.
- Main screens become readable and testable.
- User behavior remains unchanged.

---

## TASK-04 — Prayer Times Domain and Data Strategy

Goal: make prayer-time logic trustworthy and maintainable.

### 04A — Domain extraction
- [x] Extract prayer-time entities and value objects.
- [x] Extract calculation/use-case layer from UI.
- [x] Extract storage/cache access.
- [x] Add explicit data-source labels.

### TASK-04A checkpoint (2026-05-11)
- Parameter construction logic was extracted from lib/app/prayer_service.dart into lib/app/prayer_calculation_parameters_factory.dart.
- Extracted scope: method-code -> CalculationMethod mapping and advanced settings application (madhab, high-latitude rule, shafaq, rounding, per-prayer offsets).
- No fallback order, cache key/fingerprint, source access (Diyanet/Aladhan), or PrayerTimes.fromTimings behavior change intended.
### TASK-04A checkpoint 2 (2026-05-11)
- Daily prayer-time cache read/write access was extracted from lib/app/prayer_service.dart into lib/app/prayer_daily_cache_repository.dart.
- Preserved: cache key (prayer_daily_cache_v1), JSON field names, fingerprint comparison usage, and cache miss null semantics.
- No fallback order/source flow (Diyanet/Aladhan) or PrayerTimes.fromTimings orchestration change intended.
### TASK-04A checkpoint 3 (2026-05-11)
- Diyanet location city/district ID resolver logic was extracted from lib/app/prayer_service.dart into lib/app/diyanet_location_id_resolver.dart.
- Preserved: location-name normalization, ID list fetch endpoints/headers/timeouts, parsing flow, and static resolver cache behavior.
- No prayer-time fetch flow, fallback order, cache/fingerprint, or PrayerTimes.fromTimings behavior change intended.
### TASK-04A checkpoint 4 (2026-05-11)
- Diyanet prayer-time fetch/parse logic was extracted from lib/app/prayer_service.dart into lib/app/diyanet_prayer_times_client.dart.
- Preserved: prayer-times endpoint, headers, timeout, payload parsing, date fallback, minute-offset application, and null-return semantics.
- Fallback orchestration and final PrayerTimes assembly remained in PrayerService; no Aladhan/cache/fingerprint behavior change intended.
### TASK-04A checkpoint 5 (2026-05-11)
- Aladhan prayer-time fetch/parse logic was extracted from lib/app/prayer_service.dart into lib/app/aladhan_prayer_times_client.dart.
- Preserved: Aladhan API query construction, HTTP timeout/header behavior, JSON parsing/validation, invalid/missing response null semantics, and timing parse null semantics.
- Provider selection, Diyanet -> Aladhan fallback order, cache/fingerprint flow, and PrayerTimes.fromTimings orchestration remained in PrayerService.
- No behavior change intended.
### TASK-04A checkpoint 7 (2026-05-11)
- Cache fingerprint construction was extracted from lib/app/prayer_service.dart into lib/app/prayer_cache_fingerprint_builder.dart.
- Preserved exact fingerprint content and format:
  day|method|tz|country|province|district|lat|lon|madhab|highLatitude|shafaq|rounding|offsets
- Cache key usage, cache read/write flow, provider selection, fallback order, PrayerTimes.fromTimings orchestration, and app-level null/error behavior remained in PrayerService.
- No behavior change intended.
### TASK-04A checkpoint 8 (2026-05-11)
- Provider timing/result to PrayerTimes mapping helpers were extracted from lib/app/prayer_service.dart into lib/app/prayer_times_mapper.dart.
- Preserved PrayerTimes.fromTimings behavior and parameters.
- Provider calls, fallback order, cache flow, orchestration, and app-level null/error behavior remained in PrayerService.
- No behavior change intended.
### TASK-04A closure audit (2026-05-11)
- Checkpoint 1-8 extractions completed; PrayerService now primarily owns orchestration/fallback/cache decision flow.
- Further micro-extractions in 04A are deferred to avoid over-fragmentation.
- Remaining policy-level decomposition (fallback/cache/use-case layering) is deferred to a future dedicated architecture task.
- TASK-04A is considered closed; next phase is TASK-04B official data-source strategy.
### 04B — Official data access strategy
- [x] Add `docs/architecture/PRAYER_TIMES_DATA_SOURCE_STRATEGY.md`.
- [x] Record current status: waiting for CIMER/Diyanet answer.
- [x] Do not depend on hidden Diyanet endpoints as permanent architecture.
- [x] Compare options:
  - official Diyanet API or licensed data file,
  - yearly/monthly city-district offline data package,
  - verified cache generated from permitted source,
  - third-party API fallback,
  - approximate calculation fallback.
- [x] Add source transparency text in UI plan.
- [x] Add 10-city comparison test plan before release.

Acceptance:
- The app can represent source quality honestly.
- Release is blocked until source strategy is approved.

### TASK-04B closure audit (2026-05-12)
- Prayer-time data-source strategy documentation was completed.
- Covered: candidate source options, source quality label plan, UI transparency text plan, 10-city comparison test plan, and release gate criteria.
- No final source/fallback contract decision will be made before the official C�MER/Diyanet response is evaluated.
- Finalization after the official response will be handled as a separate checkpoint.
- TASK-04B is considered closed for the current documentation scope.
- [x] TASK-04B source discovery update: official AwqatSalah API sources recorded (2026-05-13).

---

## TASK-05 — Daily Ayah and Hadith Panel System

Goal: prepare the architecture now; content collection happens later.

### TASK-05 checkpoint tracking (guncel)
- [x] Checkpoint 1: audit/scope
- [x] Checkpoint 2: schema foundation (c7776a9)
- [x] Checkpoint 3: model/loader plan
- [x] Checkpoint 4: approved-only loader (64ab0e1)
- [x] Checkpoint 5: selection/state plan
- [x] Checkpoint 6: selection state implementation (e45c970)
- [x] Checkpoint 7: service/orchestrator plan
- [x] Checkpoint 8: daily content service (13a68bd)
- [x] Checkpoint 9: UI integration scope/audit (closed, 2026-05-13)
- [x] Checkpoint 10: daily ayah/hadith panel UI implementation
- [x] Checkpoint 11: daily content panel UI behavior audit (2026-05-12)
- [x] Checkpoint 12: final manual UI smoke scope (2026-05-13)
- [x] Checkpoint 13: final technical closure audit (2026-05-13)
- [x] Checkpoint 14: dataset generator scaffold (2026-05-13)

- [x] Add panel below the prayer-times panel with matching width and calm visual style.
- [x] Create `assets/data/daily_content/draft/`, `approved/`, and `archive/`.
- [x] Define JSON schema for ayah records.
- [x] Define JSON schema for hadith records.
- [x] Add required metadata fields:
  - Ayah: `id`, `type`, `surah_name`, `surah_number`, `ayah_number`, `text`, `translation`, `meal_source`, `source_note`, `topics`, `status`.
  - Hadith: `id`, `type`, `collection`, `book`, `hadith_number`, `narrator`, `text`, `translation`, `grade`, `source_note`, `topics`, `status`.
- [x] App must display only `status: approved` records.
- [x] Add daily random selection logic.
- [x] Prevent repeats until the approved list cycle is complete.
- [x] Persist `shown_ids`, `cycle_id`, `content_version`, and `daily_pick` locally.
- [x] Existing ayah/hadith files must not be treated as final production data.
- [x] Add placeholder approved sample records only for testing if needed.

Future content goal:
- [x] Rebuild content from zero with 400 approved ayahs + 400 approved hadiths.
  - Closure check (2026-05-14): approved payload counts verified as `ayah=424`, `hadith=550`.

### TASK-05B - Public Content Distribution (AllApp)

Goal: publish approved ayah/hadith content from a public repo while keeping private repo as canonical source.

- [x] Define public data contract under AllApp/data/daily_content/v1/.
- [x] Add manifest.json contract (schema_version, content_version, generated_at, file list, checksums).
- [x] Keep private repo as canonical source; generate and sync publish artifacts to public repo.
  - Sync check (2026-06-09): AllApp target is `https://github.com/mskaymaz/AllApp.git` branch `main`; remote commit `12399cd`.
- [x] Keep archive snapshots in private repo (Besmele/data/daily_panel/archive/...) as baseline history.
- [x] Add monthly packs (monthly/YYYY-MM.json) for ayah/hadith id pools.
- [x] Monthly pack generation must be random (no sequential fill).
- [x] Apply topic-based quota balancing in monthly generation (avoid same-topic streaks).
- [x] Add cooldown window across recent months to reduce repeated ids.
- [x] Add deterministic month seed for reproducible generation.
- [x] App remote fetch must read from GitHub public URL first, then fallback to local assets.
- [x] Add timeout and parse-failure fallback rules for remote fetch.
- [x] Document generation + publish runbook in repo docs.

Acceptance:
- Panel works with sample approved content.
- No unapproved content appears.
- Repeat-prevention logic is testable.

### TASK-05C - Priority / Weighted Daily Content Display

Goal: allow selected ayah/hadith items to appear more frequently without breaking trust and variety.

- [ ] Define weighted selection contract (editorial boost metadata).
- [ ] Keep default behavior backward-compatible when no weight is provided.
- [ ] Add optional per-item fields for publish-time selection metadata:
  - `priority_weight` (default: `1`)
  - `min_gap_days` (default: `0`)
  - `max_shows_per_30d` (optional safety cap)
- [ ] Add schema/documentation update under AllApp daily_content contracts.
- [ ] Add deterministic weighted order generation for publish pipeline.
- [ ] Prevent immediate repeats and enforce `min_gap_days`.
- [ ] Keep `status: approved` gate unchanged.
- [ ] Add tests:
  - weighted frequency distribution sanity,
  - min-gap enforcement,
  - fallback to unweighted mode.
- [ ] Add operator note: priority usage must remain transparent and auditable.

Acceptance:
- Priority-tagged items appear more often by design.
- Non-priority items continue to appear regularly (no starvation).
- Selection remains deterministic per content version/seed.
- No unapproved content or unsafe repetition behavior.

---

## TASK-06 — Qibla Direction Engine Upgrade

Goal: improve qibla reliability without false accuracy claims.

### 06A — Location-based mode
- [x] Store Kaaba coordinates as constants.
- [x] Implement initial bearing / great-circle direction from user coordinates to Kaaba.
- [x] Use location permission when available.
- [x] Show mode label: `Konuma gore hesaplandi`.

### 06B — Sensor fallback mode
- [x] Keep sensor-only compass fallback when location is disabled.
- [x] Show mode label: `Yaklasik / sensor tabanli`.
- [x] Add gentle guidance:
  - `Daha dogru kible yonu icin konum iznini acabilirsiniz.`
- [x] Add sensor calibration guidance.
- [x] Add accuracy warning when compass data is unstable.

### 06C — Validation
- [x] Add expected qibla bearing test values for multiple cities.
- [x] Compare calculated bearing against known references.
- [x] Do not claim 100% accuracy.

Acceptance:
- Location mode and fallback mode are visibly distinct.
- User is guided without being forced.
- Bearing calculation is covered by tests.

---

## TASK-07 — Shared Settings System

Goal: bring the reusable settings model from M_RekatSay into M_HaydiNamaza cleanly.

Required sections:
- [ ] Bize Ulasin
- [ ] Uygulama Bilgileri ve Guncelleme
- [ ] Diger Uygulamalarimiz
- [ ] Destek Olabilirsiniz
- [ ] Biz Kimiz

### TASK-07A - Settings Sections Final Review Pass

Goal: review all shared settings structures one-by-one and finalize TASK-07.

- [ ] Review and polish: Hesaplama Yontemi
- [ ] Review and polish: Hatirlatma Secenekleri (accordion)
- [ ] Review and polish: Titresimle Uyari Ayarlari (accordion)
- [ ] Review and polish: Sesli Hatirlatma (accordion)
- [ ] Review and polish: Gorsel Hatirlatma (accordion)
- [ ] Review and polish: Arayuz ve Arkaplan Renkleri (accordion)
- [ ] Review and polish: Bize Ulasin
- [ ] Review and polish: Uygulama Bilgileri ve Guncelleme
- [ ] Review and polish: Diger Uygulamalarimiz
- [ ] Review and polish: Destek Olabilirsiniz
- [ ] Review and polish: Biz Kimiz
- [ ] Run final integrated settings smoke pass and close TASK-07.

Implementation rules:
- [x] Do not blindly copy M_RekatSay files.
- [x] Extract reusable contracts and UI patterns.
- [x] App-specific values must come from config.
- [x] Contact messages must support current backend strategy.
- [x] Update check must support public APK / release manifest strategy.
- [x] Other apps catalog must support remote JSON and local fallback.
- [x] Support section must match MSK Labs philosophy.
- [x] About section must support app-specific image/text/link.

Acceptance:
- Settings page is modular.
- TASK-07 closure note (2026-05-14): shared settings template extracted to AllApp and integrated into M_HaydiNamaza with config-driven values.
- The same structure can be reused in other MSK Labs apps.
- No M_RekatSay-specific naming leaks into M_HaydiNamaza.

---

## TASK-08 — AllApp Shared Template Extraction

Goal: turn shared settings and content contracts into reusable templates.

- [x] Add shared settings template under AllApp.
- [x] Add JSON schemas for app catalog, update manifest, support, about, and contact metadata.
- [x] Add Flutter reference implementation or copy guide.
- [x] Add README explaining how each app adapts the template.
- [x] Keep AllApp as template/contracts repository, not a hidden runtime dependency.

Acceptance:
- Future MSK Labs apps can reuse the same settings pattern.
- M_HaydiNamaza remains self-contained at runtime.

---

## TASK-09 — UI/UX Professionalization

Goal: make the app feel calm, clear, and trustworthy.

- [ ] Define visual hierarchy for prayer times, daily content, qibla, settings.
- [ ] Reduce crowded screens.
- [ ] Use consistent spacing, typography, cards, and states.
- [ ] Add empty/loading/error states.
- [ ] Keep religious tone respectful and simple.
- [ ] Avoid over-animation and visual noise.

Acceptance:
- UI is cleaner without losing functionality.
- Important states are understandable.

---

## TASK-10 — Persistence, Error Handling, and Offline Reliability

Goal: make the app dependable.

- [x] Review local storage strategy.
- [x] Add safe fallback for missing/corrupt JSON.
- [x] Add prayer-time cache recovery path.
- [x] Add daily content pick recovery path.
- [x] Add location permission state recovery.
- [x] Add log-safe error reporting without exposing private data.

Acceptance:
- App does not crash on missing content, location denial, network failure, or cache corruption.

---

## TASK-11 — Tests and Validation

Goal: prevent regressions.

- [x] Add unit tests for qibla bearing calculation.
- [x] Add unit tests for daily content repeat-prevention.
- [x] Add unit tests for update/catalog JSON parsing.
- [x] Add tests for prayer-time source labels.
- [x] Add widget smoke tests for main panels where practical.
- [x] Run `flutter analyze`.

Acceptance:
- Core logic is testable outside widgets.
- New features have minimum safety coverage.

---

## TASK-12 — Release Readiness

Goal: prepare for real users.

- [x] Rewrite root `README.md` as real project README.
- [x] Add privacy note.
- [x] Add data-source transparency note.
- [x] Add release checklist.
- [x] Add build instructions.
- [x] Verify no secrets or local artifacts are committed.
- [x] Do not release until prayer-time data-source strategy is resolved.

Acceptance:
- A new developer or AI assistant can understand, build, and safely continue the project.

### Final stabilization checklist (2026-05-14)
- [x] TASK-05 content closure verified (`approved`: ayah=424, hadith=550).
- [x] TASK-05B generation + publish runbook documented in repo docs.
- [x] Official Diyanet/AwqatSalah API references recorded in strategy docs.
- [ ] Production release decision cleared (official auth/token + usage/release conditions).
- [ ] Public content sync target repo URL/branch configured (TASK-05B blocker).
- [x] Local stabilization validation commands executed and logged.










---

## TASK-13 - Erkek TTS Ses Havuzu Genisletme (Plan + Kaynak Kilidi)

Goal: Mevcut `tr-TR-AhmetNeural` sesini koruyarak 3-4 ek erkek ses secenegi sunmak.

Scope note:
- [ ] Bu gorevde once kaynak ve edinme yontemi kilitlenecek.
- [ ] Tam entegrasyon ikinci asamada (TASK-13A/TASK-13B) yapilacak.

### Kaynak matrisi (AI asistanlari icin sabit referans)

1) Mevcut ses (korunacak)
- Voice id: `tr-TR-AhmetNeural` (Male)
- Resmi kaynak:
  - https://learn.microsoft.com/en-us/azure/ai-services/speech-service/language-support
- Listeleme/yoklama yontemi:
  - `edge-tts --list-voices` (CLI listeleme)
  - https://github.com/rany2/edge-tts/blob/master/README.md
- Mobil edinme yontemi:
  - `flutter_tts.getVoices` ile cihaz/engine tarafindan donen seslerden secim.

2) Ek erkek ses #1 (offline aday)
- Voice id: `tr_TR-fahrettin-medium`
- Kaynak listesi:
  - https://github.com/rhasspy/piper/blob/master/VOICES.md
- Model dosyalari:
  - https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/tr/tr_TR/fahrettin/medium/tr_TR-fahrettin-medium.onnx
  - https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/tr/tr_TR/fahrettin/medium/tr_TR-fahrettin-medium.onnx.json
- Edinme yontemi:
  - Model + config dosyalari versiyonlu URL ile indirilir.
  - Uygulama icinde runtime TTS icin ONNX tabanli yerel piper calistirma katmani gerekir.

3) Ek erkek ses #2 (offline aday)
- Voice id: `tr_TR-fettah-medium`
- Kaynak listesi:
  - https://github.com/rhasspy/piper/blob/master/VOICES.md
- Model dosyalari:
  - https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/tr/tr_TR/fettah/medium/tr_TR-fettah-medium.onnx
  - https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/tr/tr_TR/fettah/medium/tr_TR-fettah-medium.onnx.json
- Edinme yontemi:
  - Model + config dosyalari versiyonlu URL ile indirilir.
  - Uygulama icinde runtime TTS icin ONNX tabanli yerel piper calistirma katmani gerekir.

4) Ek erkek ses #3 (offline aday)
- Voice id: `tr_TR-dfki-medium`
- Kaynak listesi:
  - https://github.com/rhasspy/piper/blob/master/VOICES.md
- Model dosyalari:
  - https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/tr/tr_TR/dfki/medium/tr_TR-dfki-medium.onnx
  - https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/tr/tr_TR/dfki/medium/tr_TR-dfki-medium.onnx.json
- Edinme yontemi:
  - Model + config dosyalari versiyonlu URL ile indirilir.
  - Uygulama icinde runtime TTS icin ONNX tabanli yerel piper calistirma katmani gerekir.

5) Opsiyonel ek erkek ses #4 (cloud multilingual fallback)
- Voice id: `en-US-RyanMultilingualNeural` (Male, multilingual)
- Resmi kaynak:
  - https://learn.microsoft.com/en-us/azure/ai-services/speech-service/language-support
- Not:
  - Multilingual sesler desteklenen dillerde (Turkce dahil) okunabilir; aksan/dogal akicilik Turkce-native seslerden farkli olabilir.
  - Bu ses flutter_tts tarafinda engine'de mevcutsa secilebilir, degilse dogrudan kullanilamaz.

### Uygulama uygunluk notu (oncesinde netlestirilecek)

- [ ] Sadece `flutter_tts` ile kalinacaksa:
  - Uygulama yalniz cihaz/engine tarafinda mevcut sesleri gosterebilir.
  - Harici Piper sesleri dogrudan "eklenemez", sadece cihazda o engine kuruluysa secilebilir.
- [ ] Piper sesleri kesin eklenecekse:
  - Android/iOS icin yerel TTS runtime (ONNX + native bridge) tasarimi gerekir.
  - Paket boyutu, lisans, performans, offline depolama ve model guncelleme akisi netlestirilmelidir.

Acceptance (TASK-13 plan asamasi):
- Kaynak URL'leri sabit ve versiyonlu olarak dokumante edildi.
- Hangi sesin hangi yolla alinacagi acikca yazildi.
- Implementasyon oncesi teknik secim kapisi tanimlandi.

---

## JSON Duzeltme Kaydi (Daily Content)

Tarih: 2026-05-22

- Besmele/data/daily_panel/publish/hadisler.json
  - Unicode/encoding yapisi duzeltildi.
  - `text_ar`, `text_tr`, `text_en` alanlari tamlik kontrolunden gecirildi.
- Besmele/data/daily_panel/publish/ayetler.json
  - Unicode/encoding yapisi kontrol edildi ve temiz durum kayda alindi.
  - `text_ar`, `text_tr`, `text_en` alanlari tamlik kontrolunden gecirildi.
- assets/data/daily_content/approved/hadiths.v1.approved.json
  - Unicode/encoding yapisi duzeltildi.
  - `text_ar`, `text_tr`, `text_en` alanlari tamlik kontrolunden gecirildi.
- assets/data/daily_content/approved/ayahs.v1.approved.json
  - Unicode/encoding yapisi kontrol edildi ve temiz durum kayda alindi.
  - `text_ar`, `text_tr`, `text_en` alanlari tamlik kontrolunden gecirildi.

### AllApp Uzak Yayin Kaydi

Tarih: 2026-06-09
Hedef uzak repo: `https://github.com/mskaymaz/AllApp.git`
Hedef branch: `main`
Uzak commit: `12399cd`
Content version: `local-approved-20260609_074542`

Yuklenen JSON dosyalari:
- data/daily_content/v1/manifest.json
- data/daily_content/v1/publish/ayahs.v1.approved.json (`record_count=37`)
- data/daily_content/v1/publish/hadiths.v1.approved.json (`record_count=8`)

Not:
- AllApp publish dosyalari yerel `assets/data/daily_content/approved/` kayitlarindan yeniden uretildi.
- Eski uzak publish havuzundaki kayit listesi korunmadi; ciktida yalniz yerel approved ayet/hadis kayitlari var.
- Uygulama runtime base URL: `https://raw.githubusercontent.com/mskaymaz/AllApp/main/data/daily_content/v1`.

### Onceki AllApp Uzak Yayin Kaydi

Tarih: 2026-05-22
R etiketi: `R260522_0117`
Hedef uzak repo: `https://github.com/mskaymaz/AllApp.git`
Hedef branch: `main`
Uzak commit: `ec4afb0`

Yuklenen JSON dosyalari (sadece ayet/hadis):
- data/daily_content/v1/publish/ayahs.v1.approved.json
- data/daily_content/v1/publish/hadiths.v1.approved.json

Not:
- Hedefte ayni isimli dosya bulunursa `*.old.R<zaman>` kurali ile eski dosya adlandirilip yeni dosya gecerli dosya olarak yuklenecek sekilde akisa alindi.
- Bu kayit, ileride AllApp uzerindeki gecerli publish dosyalarina hizli erisim icin tutulur.

### Local JSON Arsivleme Kaydi

Tarih: 2026-05-22
Amac: Inceleme aracinda karmasayi azaltmak icin aktif cift disindaki publish JSON dosyalarini ayri arsive tasima.

Aktif birakilanlar:
- Besmele/data/daily_panel/publish/ayetler.json
- Besmele/data/daily_panel/publish/hadisler.json

Arsive tasinanlar:
- Besmele/data/daily_panel/archive/pending_json_2026-05-22_084948/ayahs.v1.approved.json
- Besmele/data/daily_panel/archive/pending_json_2026-05-22_084948/hadiths.v1.approved.json
- Besmele/data/daily_panel/archive/pending_json_2026-05-22_084948/sequence.v1.json

### Daily Content Kaynak Onay Guncellemesi

Tarih: 2026-05-29

Amac: Ayet/hadis ekleme paneli icin "hangi veri nereden cekiliyor" notlarini tek yerde netlestirmek.

- Diyanet Kuran API erisim kapisi dogrulandi:
  - `https://acikkaynakkuran-dev.diyanet.gov.tr/`
  - Not: API anahtari almak icin GitHub ile giris gerektirir.
- Diyanet acik kaynak Kuran istemci reposunda da token gereksinimi notu var:
  - `https://github.com/diyanet-bid/Kuran`
- Ayet cekimi icin dokumante edilmis endpointler dogrulandi (islamic.app):
  - Dokuman: `https://docs.islamic.app/api-reference/verses`
  - Ornek endpoint: `GET /v1/verses/by_key/{surah}:{ayah}`
- Riyazus Salihin hadis cekimi icin dokumante edilmis endpointler dogrulandi (islamic.app):
  - Dokuman: `https://docs.islamic.app/api-reference/hadith-hadiths`
  - Ornek endpoint: `GET /v1/hadith/collections/riyadussalihin/books/{bookNumber}/hadiths/{hadithNumber}`
- islamic.app kullanim sinirlari ve erisim modeli dogrulandi:
  - Kimlik dogrulama: `no signup, no API key` (dokumana gore)
  - Limit: `1000 request/saat/IP`
  - Referanslar:
    - `https://docs.islamic.app/quickstart`
    - `https://docs.islamic.app/concepts/rate-limits`
- Kaynak/attribution notu:
  - islamic.app hadith verisinin sunnah.com aynasini kullandigini belirtir; yayin oncesi atif/lisans notu korunmalidir.
  - Referans: `https://islamic.app/attributions`

Operasyonel sonuc (bu tarih itibariyla):
- Diyanet tokeni mevcutsa TR ayet metni/meali Diyanet API'den alinabilir.
- AR/EN ayet ve Riyazus Salihin hadis metinlerinde islamic.app cekimi teknik olarak uygulanabilir.
- Tum otomatik cekilen kayitlar panelde insan onayindan gecmeden `approved` yapilmaz.
arayüz sıkıntılı. metinler yukarıdan aşağıya akıyor. Derin bir kontrol yapıp düzelt.
