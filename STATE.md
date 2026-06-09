# STATE.md

last_update: 2026-06-09
project: M_HaydiNamaza
status: bulk_daily_content_esma_sifat_remote_publish_ready_pending_allapp_push
active_phase: advanced_architecture_upgrade
active_task: TASK-09-ui-ux-professionalization-in-progress
blockers:
  - Production release remains blocked until official Diyanet/AwqatSalah access contract (auth/token + usage/release decision) is explicitly cleared.
next_step:
  - Continue ayah and hadith review from `assets/data/daily_content/archive/`.
  - Keep approved runtime payloads under `assets/data/daily_content/approved/`.
  - Sync/push AllApp publish artifacts after local approved ayah/hadith/esma-sifat changes.
  - Keep TASK-09 and later tasks pending until explicit instruction.

## Current known risks
- Existing large UI files must be split safely.
- Prayer-time official access/release contract is still an active release gate.
- Diyanet/AwqatSalah official API references are documented; production decision remains pending until explicit access/usage clearance.
- Qibla direction must distinguish mathematical bearing from sensor accuracy.
- Daily content archive/approved roots were unified on 2026-06-04 and the Python review tool now depends on those fixed paths.
- AllApp public content sync target is `https://github.com/mskaymaz/AllApp.git` branch `main`; latest daily content publish sync commit is `12399cd`.
- Local approved counts after 2026-06-09 Esma/Sıfat import: `ayah=1438`, `hadith=438`, `esma/sifat=381` (`esma=99`, `sifat=282`); AllApp local publish artifacts are generated and remote push is still pending.
