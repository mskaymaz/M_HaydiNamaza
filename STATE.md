# STATE.md

last_update: 2026-05-10
project: M_HaydiNamaza
status: task_00_completed_with_documented_exceptions
active_phase: advanced_architecture_upgrade
active_task: TASK-00-closed-awaiting-task-01-start
blockers:
  - Official Diyanet prayer-time data access is unresolved and must be settled before release.
next_step:
  - Do not start TASK-01/TASK-02/TASK-04 until explicit user instruction.
  - Continue work from `Besmele/TASKS.md`.

## Current known risks
- Existing large UI files must be split safely.
- Prayer-time data source must not rely on fragile hidden endpoints.
- Existing ayah/hadith content will be replaced later with a new approved 400 + 400 dataset.
- Qibla direction must distinguish mathematical bearing from sensor accuracy.

