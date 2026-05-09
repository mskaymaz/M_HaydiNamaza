# STATE.md

last_update: 2026-05-09
project: M_HaydiNamaza
status: instruction_cleanup_ready
active_phase: advanced_architecture_upgrade
active_task: TASK-00-baseline-and-instruction-cleanup
blockers:
  - Official Diyanet prayer-time data access is unresolved and must be settled before release.
next_step:
  - Apply clean instruction structure.
  - Archive old duplicated markdown/task/Besmele files.
  - Start baseline audit from `Besmele/TASKS.md`.

## Current known risks
- Instruction/task files are duplicated and can confuse AI assistants.
- Existing large UI files must be split safely.
- Prayer-time data source must not rely on fragile hidden endpoints.
- Existing ayah/hadith content will be replaced later with a new approved 400 + 400 dataset.
- Qibla direction must distinguish mathematical bearing from sensor accuracy.

