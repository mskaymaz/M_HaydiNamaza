# HANDOFF.md

## Current status
TASK-03 is closed and pushed on `main`.
TASK-00 is completed on 2026-05-10 with documented exceptions.
TASK-04A first implementation step is completed (parameter factory extraction only).
TASK-04A checkpoint 2 is completed (daily cache repository extraction only).
TASK-04A checkpoint 3 is completed (Diyanet location ID resolver extraction only).

## Next action
Wait for explicit start instruction before TASK-01.

## Important blockers
- Official Diyanet prayer-time data access is not resolved yet.
- Existing ayah/hadith content will be replaced later with a new approved dataset.

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

