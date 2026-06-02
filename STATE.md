# STATE.md

last_update: 2026-06-02
project: M_HaydiNamaza
status: daily_content_reset_started_clean_seed_created
active_phase: advanced_architecture_upgrade
active_task: TASK-09-not-started-release-gate-active
blockers:
  - Production release remains blocked until official Diyanet/AwqatSalah access contract (auth/token + usage/release decision) is explicitly cleared.
  - TASK-05B public sync remains blocked until public target repo URL/branch is defined.
next_step:
  - Rebuild ayah and hadith source lists from the new clean seed files.
  - Recreate approved runtime payloads only after the new source pool is reviewed.
  - Keep TASK-09 and later tasks pending until explicit instruction.

## Current known risks
- Existing large UI files must be split safely.
- Prayer-time official access/release contract is still an active release gate.
- Diyanet/AwqatSalah official API references are documented; production decision remains pending until explicit access/usage clearance.
- Public content distribution sync target (repo/branch) is still not configured.
- Qibla direction must distinguish mathematical bearing from sensor accuracy.
- Daily content repository was reset on 2026-06-02; ayah and hadith pools are intentionally empty until refill.
