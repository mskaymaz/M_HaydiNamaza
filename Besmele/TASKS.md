# M_HaydiNamaza â€” Advanced Upgrade Tasks

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

## TASK-00 â€” Baseline Safety and Instruction Cleanup

Goal: make the repo understandable before code changes.

- [ ] Create branch `upgrade/advanced-cleanup`.
- [ ] Confirm current app baseline with `flutter pub get`.
- [ ] Run `flutter analyze` and save result summary in `Besmele/HANDOFF.md`.
- [ ] Archive old duplicated instruction files into `_archive_instruction_old/<timestamp>/`.
- [ ] Keep only root `AGENTS.md`, `CORE.md`, `STATE.md`, and `Besmele/` as active instruction system.
- [ ] Remove active duplicate folders from instruction flow: `BesmeleGenel`, `ContextKit`, root `core/rules/flows/plans/sessions/oturumlar/hooks/optional/tools` if they only contain AI instruction material.
- [ ] Keep old files in archive, not permanent delete.
- [ ] Verify Codex/Copilot startup path is clear.

Acceptance:
- One active instruction hierarchy remains.
- Old documents are recoverable from archive.
- No app code changed.

---

## TASK-01 â€” Current Architecture Map

Goal: understand the app before refactoring.

- [ ] Create `docs/architecture/CURRENT_ARCHITECTURE.md`.
- [ ] List main app entry points.
- [ ] List current feature folders.
- [ ] List all files over 600 lines.
- [ ] Identify UI files that contain business logic.
- [ ] Identify services that mix unrelated responsibilities.
- [ ] Identify prayer-time, qibla, settings, notification, location, and content flows.
- [ ] Record safe refactor order.

Acceptance:
- Refactor order is documented.
- No code behavior changed.

---

## TASK-02 â€” Target Architecture Skeleton

Goal: create structure without moving risky behavior yet.

- [ ] Create or align `lib/app/` for app shell, config, theme, routing.
- [ ] Create or align `lib/core/` for shared constants, storage, errors, logging, platform utilities, common widgets.
- [ ] Create or align `lib/features/prayer_times/`.
- [ ] Create or align `lib/features/qibla/`.
- [ ] Create or align `lib/features/daily_content/`.
- [ ] Create or align `lib/features/shared_settings/`.
- [ ] Create or align `lib/features/location/`.
- [ ] Create or align `lib/features/notifications/`.
- [ ] Add barrel files only if they reduce import noise.

Acceptance:
- New folders exist.
- No functional behavior changed.
- `flutter analyze` does not get worse because of empty/unused broken files.

---

## TASK-03 â€” Large File Decomposition

Goal: split oversized files safely.

- [ ] Split `home_screen.dart` into layout, panels, actions, and state helpers.
- [x] Split `settings_screen.dart` into focused settings cards/sections.
- [ ] Split `location_screen.dart` into permission view, search view, result view, and controller/service logic.
- [x] Move pure UI widgets first.
- [ ] Move business logic only after widget extraction is stable.
- [ ] Keep each step compile-safe.
- [ ] Delete dead code only after validation.

### TASK-03A — settings_screen.dart UI decomposition

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

### TASK-03B — location_screen.dart safe UI/helper extraction checkpoint

- [x] Extract location name formatting helpers.
- [x] Extract location add-favorite button.
- [x] Extract location selection composer.
- [x] Extract generic dropdown item builder.
- [x] Stop further micro UI/helper extraction to avoid over-fragmentation.
- [ ] Audit location orchestration/service/repository boundaries.

Acceptance:
- No file remains above 600 lines unless documented.
- Main screens become readable and testable.
- User behavior remains unchanged.

---

## TASK-04 â€” Prayer Times Domain and Data Strategy

Goal: make prayer-time logic trustworthy and maintainable.

### 04A â€” Domain extraction
- [ ] Extract prayer-time entities and value objects.
- [ ] Extract calculation/use-case layer from UI.
- [ ] Extract storage/cache access.
- [ ] Add explicit data-source labels.

### 04B â€” Official data access strategy
- [ ] Add `docs/architecture/PRAYER_TIMES_DATA_SOURCE_STRATEGY.md`.
- [ ] Record current status: waiting for CIMER/Diyanet answer.
- [ ] Do not depend on hidden Diyanet endpoints as permanent architecture.
- [ ] Compare options:
  - official Diyanet API or licensed data file,
  - yearly/monthly city-district offline data package,
  - verified cache generated from permitted source,
  - third-party API fallback,
  - approximate calculation fallback.
- [ ] Add source transparency text in UI plan.
- [ ] Add 10-city comparison test plan before release.

Acceptance:
- The app can represent source quality honestly.
- Release is blocked until source strategy is approved.

---

## TASK-05 â€” Daily Ayah and Hadith Panel System

Goal: prepare the architecture now; content collection happens later.

- [ ] Add panel below the prayer-times panel with matching width and calm visual style.
- [ ] Create `assets/data/daily_content/draft/`, `approved/`, and `archive/`.
- [ ] Define JSON schema for ayah records.
- [ ] Define JSON schema for hadith records.
- [ ] Add required metadata fields:
  - Ayah: `id`, `type`, `surah_name`, `surah_number`, `ayah_number`, `text`, `translation`, `meal_source`, `source_note`, `topics`, `status`.
  - Hadith: `id`, `type`, `collection`, `book`, `hadith_number`, `narrator`, `text`, `translation`, `grade`, `source_note`, `topics`, `status`.
- [ ] App must display only `status: approved` records.
- [ ] Add daily random selection logic.
- [ ] Prevent repeats until the approved list cycle is complete.
- [ ] Persist `shown_ids`, `cycle_id`, `content_version`, and `daily_pick` locally.
- [ ] Existing ayah/hadith files must not be treated as final production data.
- [ ] Add placeholder approved sample records only for testing if needed.

Future content goal:
- [ ] Rebuild content from zero with 400 approved ayahs + 400 approved hadiths.

Acceptance:
- Panel works with sample approved content.
- No unapproved content appears.
- Repeat-prevention logic is testable.

---

## TASK-06 â€” Qibla Direction Engine Upgrade

Goal: improve qibla reliability without false accuracy claims.

### 06A â€” Location-based mode
- [ ] Store Kaaba coordinates as constants.
- [ ] Implement initial bearing / great-circle direction from user coordinates to Kaaba.
- [ ] Use location permission when available.
- [ ] Show mode label: `Konuma gore hesaplandi`.

### 06B â€” Sensor fallback mode
- [ ] Keep sensor-only compass fallback when location is disabled.
- [ ] Show mode label: `Yaklasik / sensor tabanli`.
- [ ] Add gentle guidance:
  - `Daha dogru kible yonu icin konum iznini acabilirsiniz.`
- [ ] Add sensor calibration guidance.
- [ ] Add accuracy warning when compass data is unstable.

### 06C â€” Validation
- [ ] Add expected qibla bearing test values for multiple cities.
- [ ] Compare calculated bearing against known references.
- [ ] Do not claim 100% accuracy.

Acceptance:
- Location mode and fallback mode are visibly distinct.
- User is guided without being forced.
- Bearing calculation is covered by tests.

---

## TASK-07 â€” Shared Settings System

Goal: bring the reusable settings model from M_RekatSay into M_HaydiNamaza cleanly.

Required sections:
- [ ] Bize Ulasin
- [ ] Uygulama Bilgileri ve Guncelleme
- [ ] Diger Uygulamalarimiz
- [ ] Destek Olabilirsiniz
- [ ] Biz Kimiz

Implementation rules:
- [ ] Do not blindly copy M_RekatSay files.
- [ ] Extract reusable contracts and UI patterns.
- [ ] App-specific values must come from config.
- [ ] Contact messages must support current backend strategy.
- [ ] Update check must support public APK / release manifest strategy.
- [ ] Other apps catalog must support remote JSON and local fallback.
- [ ] Support section must match MSK Labs philosophy.
- [ ] About section must support app-specific image/text/link.

Acceptance:
- Settings page is modular.
- The same structure can be reused in other MSK Labs apps.
- No M_RekatSay-specific naming leaks into M_HaydiNamaza.

---

## TASK-08 â€” AllApp Shared Template Extraction

Goal: turn shared settings and content contracts into reusable templates.

- [ ] Add shared settings template under AllApp.
- [ ] Add JSON schemas for app catalog, update manifest, support, about, and contact metadata.
- [ ] Add Flutter reference implementation or copy guide.
- [ ] Add README explaining how each app adapts the template.
- [ ] Keep AllApp as template/contracts repository, not a hidden runtime dependency.

Acceptance:
- Future MSK Labs apps can reuse the same settings pattern.
- M_HaydiNamaza remains self-contained at runtime.

---

## TASK-09 â€” UI/UX Professionalization

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

## TASK-10 â€” Persistence, Error Handling, and Offline Reliability

Goal: make the app dependable.

- [ ] Review local storage strategy.
- [ ] Add safe fallback for missing/corrupt JSON.
- [ ] Add prayer-time cache recovery path.
- [ ] Add daily content pick recovery path.
- [ ] Add location permission state recovery.
- [ ] Add log-safe error reporting without exposing private data.

Acceptance:
- App does not crash on missing content, location denial, network failure, or cache corruption.

---

## TASK-11 â€” Tests and Validation

Goal: prevent regressions.

- [ ] Add unit tests for qibla bearing calculation.
- [ ] Add unit tests for daily content repeat-prevention.
- [ ] Add unit tests for update/catalog JSON parsing.
- [ ] Add tests for prayer-time source labels.
- [ ] Add widget smoke tests for main panels where practical.
- [ ] Run `flutter analyze`.

Acceptance:
- Core logic is testable outside widgets.
- New features have minimum safety coverage.

---

## TASK-12 â€” Release Readiness

Goal: prepare for real users.

- [ ] Rewrite root `README.md` as real project README.
- [ ] Add privacy note.
- [ ] Add data-source transparency note.
- [ ] Add release checklist.
- [ ] Add build instructions.
- [ ] Verify no secrets or local artifacts are committed.
- [ ] Do not release until prayer-time data-source strategy is resolved.

Acceptance:
- A new developer or AI assistant can understand, build, and safely continue the project.
