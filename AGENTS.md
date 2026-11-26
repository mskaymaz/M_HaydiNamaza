# AGENTS.md

Repo: M_HaydiNamaza

This file is the only bootstrap file for AI coding assistants.

## Mandatory startup
1. Read `CORE.md`.
2. Read `STATE.md`.
3. Read `Besmele/TASKS.md` only for implementation planning.
4. Read only task-relevant source files before editing.

## Runtime commands
- `bismillah` or `eko`: strict scoped mode.
  - Required response: `Bismillah, baglam alindi, calismaya hazirim.`
  - Work only on the requested scope.
  - Use minimum files and minimum explanation.
  - Do not propose unrelated features.
- `fren`: stop immediately.

## Editing rules
- Do not rewrite the full app in one step.
- Preserve working behavior before improving it.
- Keep files preferably under 400 lines; 600 lines only if unavoidable.
- Before starting and before finishing any code-file edit, silently check the line count of each touched code file. Do not report this check to the user unless a touched code file exceeds or would exceed 600 lines. If a touched code file would exceed 600 lines, split it into appropriate smaller files instead of leaving it above 600 lines.
- UI renders state and sends actions; business logic belongs to services/domain.
- When a requested UI size/spacing change is given as a ratio or percent, calculate the final value first and commit the nearest clear literal value. Do not leave request-derived size expressions such as `base * 1.30`, `value + value * 0.30`, or temporary percentage math in code.
- Do not hardcode app-specific text inside reusable shared modules.
- Never commit secrets, service-account files, local build folders, generated zip files, or private credentials.

## Output rules
- Be brief and factual.
- Always list changed files.
- Always list validation command results or say clearly that validation was not run.
- Update `STATE.md` and `Besmele/HANDOFF.md` only when the task changes project status.

## Validation preference (user workflow)
- For `flutter analyze` and similar validation commands, ask the user to run the command and share the terminal output.
- Prefer user-provided validation output in this repo unless the user explicitly asks the assistant to run validations directly.

## Device testing workflow (mandatory)
- Before the user performs the separate debug/test flow on the phone, first remind the user to run `flutter build apk --debug` from the repository root.
- Treat a successful `flutter build apk --debug` as the computer-side build checkpoint before phone testing.
- Do not install the generated APK to the phone as part of this workflow unless the user explicitly asks; phone testing uses the user's separate debug process.
- At the end of implementation work, always remind the user of the `flutter build apk --debug` command and ask them to share its result before proceeding to phone testing.


## Ekosistem Telemetri & Dağıtım Kuralı (IST-013 / IST-016 / IST-017)
- Uygulama güncelleme veya yeni sürüm yayınlama işlerinde kök dizindeki `ECO_TELEMETRY_GUIDE.md` (ve merkezi `D:\Code\istisare\istisareler\017-eco-sdk-istemci-entegrasyon-rehberi.md`) kuralları **zorunlu** olarak uygulanır.
- Kapanışta telemetri atılmaz; açılışta `launch_count` biriktirilip ilk/yeniden kurulumda, sürüm değişiminde ve 7 günde 1 gönderilir. Ayarlara opt-out anahtarı/pop-up konulmaz (mağaza uygulamalarında `privacy.html` & Data Safety beyanı korunur).

## Response Budget & Commit Format (Mandatory)
- **<= 10 Lines Limit:** Keep ALL replies concise, bulleted, and strictly **<= 10 lines total** (1–3 lines for Yes/No, max 1–2 lines/single sentence per bullet). No unrequested elaboration unless asked.
- **Commit Format:** On user-approved commits, summarize the change clearly in Turkish followed by `(yy/mm/dd_hh.mm)` (e.g., `Aktif hesap okuma düzeltildi (26/11/25_15.42)`).


## Zorunlu Release, Tag & İkili Dosya Adlandırma Kuralı (IST-015 / IST-016)
> **SSOT:** `D:\Code\istisare\istisareler\015-merkezi-release-tag-ve-surum-yayin-protokolu.md` (`IST-015`) & `016-melez-hizli-dagitim-r2-ve-worker-cache-mimarisi.md` (`IST-016`).

- **Git Geçmişine İkili Dosya Konmaz:** Derlenen dosyalar (`dist/`, `build/`, `*.exe`, `*.apk`, `*.zip`) `.gitignore` içinde kalır; dağıtım yalnızca **GitHub Releases / R2** üzerinden yapılır.
- **Genel / Debug Dosya Adı Yasağı (Yerel + Uzak):** Yerel debug/release derlemelerinde (`PyInstaller --name`, Flutter çıktı adı vb.) ve uzak Release'lerde `main.exe`, `app.exe`, `app-release.apk`, `app-debug.apk` veya `release.apk` gibi genel isimler **kesinlikle kullanılmaz**. Yerel çıktılar daima gerçek uygulama adıyla (ör. `RekatSay-debug.apk`, `PushPull.exe`), yayınlanan/indirilen release dosyaları ise **`<UygulamaAdı>-<sürüm>.<uzantı>`** (ör. `RekatSay-v1.3.1.apk`, `PushPull-v1.0.2.exe`) formatında üretilir.
- **Kesin Hedef Ayrımı:** Son kullanıcıya açık (Public) uygulamalar **`mskaymaz/MSKLabsApps` Releases** (`<app-slug>-vX.Y.Z` tag'iyle) + Cloudflare R2 (`r2_keep_versions: 2`) üzerinden; bireysel/iç araçlar (`PushPull`, `TokenGemini` vb.) ise **kendi GitHub reposunun Releases sekmesinden** yayınlanır.
