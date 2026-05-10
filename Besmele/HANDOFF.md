# HANDOFF.md

## Current status
TASK-03 is closed and pushed on `main`.
TASK-00 documentation audit was completed on 2026-05-10 with documented exceptions.

## Next action
Close the remaining TASK-00 baseline evidence item by explicitly recording `flutter pub get` when allowed.

## Important blockers
- Official Diyanet prayer-time data access is not resolved yet.
- Existing ayah/hadith content will be replaced later with a new approved dataset.

## TASK-00 audit notes (2026-05-10)
- Branch `upgrade/advanced-cleanup` is treated as obsolete for now because cleanup work already landed on `main` and `origin/main` is aligned.
- Duplicate instruction roots are absent at repo root: `BesmeleGenel`, `ContextKit`, `core`, `rules`, `flows`, `plans`, `sessions`, `oturumlar`, `hooks`, `optional`.
- Archived instruction material exists in `_archive_instruction_old_20260509_131932/` and `_archive_instruction_old_20260509_132105/`.
- `flutter analyze` was not run in this audit; user-reported baseline remains `No issues found!`.
- `flutter pub get` was not run in this audit by scope constraint and remains the only open TASK-00 checklist item.
- Root `tools/` remains intentionally active because it contains utility scripts, not instruction-only duplicates.

## Do not forget
- The app must stay working during refactors.
- Large files must be split gradually.
- Shared settings must be reusable across MSK Labs apps.

