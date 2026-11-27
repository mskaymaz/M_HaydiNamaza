# STATE.md

last_update: 2026-07-15
project: M_HaydiNamaza
status: ui_engine_stabilization_checkpoint_ready_for_home_continuation
active_phase: advanced_architecture_upgrade
active_task: TASK-09-ui-ux-professionalization-in-progress; prayer-silence-flow-implementation-in-progress
blockers:
  - Official Diyanet/AwqatSalah access remains unresolved; current release direction is calculation-based stabilization with honest source labeling.
next_step:
  - Computer-side debug build checkpoint passed on 2026-07-15; proceed with separate phone validation after reviewing the generated debug APK.
  - Run user-side validation for the new prayer silence settings, per-prayer icon toggles, Android policy access flow, and background restore behavior.
  - Continue UI and prayer-time engine stabilization from the main screen, settings, qibla, and daily content flows.
  - Keep approved runtime payloads under `assets/data/daily_content/approved/`.
  - Keep AllApp publish artifacts synced after future approved content changes.
  - AllAppRemote cleanup was committed and pushed on 2026-07-15 at `d6a2938`; the root repo now tracks that clean AllApp main state.
  - Shared settings template v2 is now the canonical AllApp contract/reference; validate the settings flow after this refactor.

## Current known risks
- 2026-06-11 AllApp remote push completed for approved ayah/hadith/esma-sifat publish artifacts; remote commit is `39fe32b`.
- Existing large UI files must be split safely.
- Prayer-time official access/release contract is still unresolved; do not claim official Diyanet equivalence unless access/usage is cleared.
- Diyanet/AwqatSalah official API references are documented; production direction is calculation-based stabilization unless a new official data decision is made.
- Qibla direction must distinguish mathematical bearing from sensor accuracy.
- Daily content archive/approved roots were unified on 2026-06-04 and the Python review tool now depends on those fixed paths.
- AllApp public content sync target is `https://github.com/mskaymaz/AllApp.git` branch `main`; latest daily content publish sync commit is `39fe32b`.
- Local approved counts after 2026-06-09 Esma/Sifat import: `ayah=1438`, `hadith=438`, `esma/sifat=381` (`esma=99`, `sifat=282`); AllApp publish artifacts were pushed on 2026-06-11.
- Shared settings alignment completed on 2026-07-14: AllApp v2 now documents the four-section contract, current catalog/manifest/config schemas, examples, and v1 is marked legacy. Haydi Namaza uses the config-driven support action and local update-manifest fallback.
- User-side validation on 2026-07-14: `flutter analyze` passed with `No issues found!`; dependency update notices remain non-blocking.

## IST-001 Denetim Hatırlatıcısı (27.11.2026)
> Yeni oturumda çalışmaya başlandığında önce aşağıdaki eksikler `IST-001` (`D:\Code\mskaymaz\istisare\istisareler\001-uygulama-anayasasi-ve-repo-mimarisi.md`) doğrultusunda ele alınır:
- [ ] Kodda `Eco-SDK` (`eco_device_id` + 7 günlük `/api/v1/telemetry/heartbeat`) entegrasyonu yapılacak.
- [ ] Eksik SSOT belgesi `tasks.md` eklenecek; `docs/kullanim_kilavuzu/{tr,en,ar}` + uygulama içi yardım doğrulanacak.
- [ ] `tools/content_review/` altında `>650` satırı aşan `4` dosya modülerleştirilecek.
