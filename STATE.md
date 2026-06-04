# STATE.md

last_update: 2026-06-04
project: M_HaydiNamaza
status: daily_content_review_tool_mobile_preview_ready_archive_paths_unified
active_phase: advanced_architecture_upgrade
active_task: TASK-09-not-started-release-gate-active
blockers:
  - Production release remains blocked until official Diyanet/AwqatSalah access contract (auth/token + usage/release decision) is explicitly cleared.
  - TASK-05B public sync remains blocked until public target repo URL/branch is defined.
next_step:
  - Continue ayah and hadith review from `assets/data/daily_content/archive/`.
  - Keep approved runtime payloads under `assets/data/daily_content/approved/`.
  - Refill ayah/hadith approved payloads after manual review in the Python tool.
  - Keep TASK-09 and later tasks pending until explicit instruction.

## Current known risks
- Existing large UI files must be split safely.
- Prayer-time official access/release contract is still an active release gate.
- Diyanet/AwqatSalah official API references are documented; production decision remains pending until explicit access/usage clearance.
- Public content distribution sync target (repo/branch) is still not configured.
- Qibla direction must distinguish mathematical bearing from sensor accuracy.
- Daily content archive/approved roots were unified on 2026-06-04 and the Python review tool now depends on those fixed paths.
