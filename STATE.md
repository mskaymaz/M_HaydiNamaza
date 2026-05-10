# STATE.md

last_update: 2026-05-10
project: M_HaydiNamaza
status: task_01_completed_architecture_map_ready
active_phase: advanced_architecture_upgrade
active_task: TASK-01-current-architecture-map-closed
blockers:
  - Official Diyanet prayer-time data access is unresolved and must be settled before release.
next_step:
  - Do not start TASK-02/TASK-04 until explicit user instruction.
  - Keep TASK-01 architecture map as baseline for later refactors.
  - Continue work from `Besmele/TASKS.md`.

## Current known risks
- Existing large UI files must be split safely.
- Prayer-time data source must not rely on fragile hidden endpoints.
- Existing ayah/hadith content will be replaced later with a new approved 400 + 400 dataset.
- Qibla direction must distinguish mathematical bearing from sensor accuracy.

