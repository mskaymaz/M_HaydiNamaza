# STATE.md

last_update: 2026-05-10
project: M_HaydiNamaza
status: task_00_audit_completed_with_documented_exceptions
active_phase: advanced_architecture_upgrade
active_task: TASK-00-baseline-and-instruction-cleanup
blockers:
  - Official Diyanet prayer-time data access is unresolved and must be settled before release.
next_step:
  - Keep TASK-00 open only for explicit `flutter pub get` confirmation record.
  - Do not start TASK-01/TASK-02/TASK-04 until TASK-00 is fully closed.
  - Continue work from `Besmele/TASKS.md`.

## Current known risks
- Baseline command evidence is incomplete: `flutter pub get` was not executed in the 2026-05-10 audit scope.
- Existing large UI files must be split safely.
- Prayer-time data source must not rely on fragile hidden endpoints.
- Existing ayah/hadith content will be replaced later with a new approved 400 + 400 dataset.
- Qibla direction must distinguish mathematical bearing from sensor accuracy.

