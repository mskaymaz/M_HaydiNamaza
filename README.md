# M_HaydiNamaza

M_HaydiNamaza is a Flutter prayer-time application focused on reliability, clarity, and offline-safe behavior.

## Current Status
- Active branch target: `main`
- TASK-05 content scope completed (`approved` counts: ayah=424, hadith=550)
- TASK-05B publish runbook documented (`docs/architecture/DAILY_CONTENT_PUBLISH_RUNBOOK.md`)
- TASK-06 completed (qibla direction upgrade)
- TASK-10 completed (persistence/error/offline safeguards)
- TASK-11 completed for current scope in task tracking flow
- Final production release is blocked until official Diyanet/AwqatSalah access contract (auth/token + usage/release decision) is explicitly cleared

## Core Features
- Daily prayer times with fallback strategy
- Qibla direction (location-based + sensor fallback)
- Daily approved ayah/hadith panel with repeat-prevention logic
- Location/favorites/settings persistence via local storage

## Build Instructions
1. Install Flutter SDK compatible with project constraints.
2. Get dependencies:
   - `flutter pub get`
3. Run app:
   - `flutter run`
4. Build Android release:
   - `flutter build apk --release`

## Privacy Note
- The app stores user settings and local preferences on-device (location selection, reminders, UI settings, daily content state).
- The app does not require account creation for core usage.
- No private credentials or service-account files should be committed to this repository.

## Data-Source Transparency Note
- Prayer-time source strategy is documented in:
  - `docs/architecture/PRAYER_TIMES_DATA_SOURCE_STRATEGY.md`
- Source quality and release gating rules are defined there.
- Production release remains blocked until official access/release decision is cleared.

## Release Checklist
- [x] Root README is project-specific and actionable.
- [x] Privacy note exists.
- [x] Data-source transparency note exists.
- [x] Build instructions exist.
- [x] Repository checked for committed secrets/local artifacts in tracked files.
- [x] Release blocker is explicitly preserved until official prayer-time source/release decision is cleared.

## Repository Safety Notes
- Do not commit:
  - secrets or credentials
  - service-account files
  - local build artifacts
  - generated private archives
- Keep architecture/task tracking in:
  - `Besmele/TASKS.md`
  - `STATE.md`
  - `Besmele/HANDOFF.md`
