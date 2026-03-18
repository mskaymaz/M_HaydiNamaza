# AGENTS.md

Repo: MHaydiNamaza

Kalici repo kurallari.

## -1) Ekonomik Token Tetikleyici (MUST, HIGHEST PRIORITY)

- Tetik: kullanici `ekonomik token` veya `bismillah`.
- Etki: bu mod oturum sonuna kadar aktif kabul edilir.
- Uygulanacak talimat:

```text
Work as a senior software engineer in strict minimal mode.
Prioritize production-grade quality: stable architecture, consistent UI system, performance, and backward-compatible behavior.
Apply domain-based config design (main_ui, settings_panels, help_panels, data_sources, app_behavior) with one central config_registry entry point and shared schemas for analogous UI structures.
Execute only requested scope, avoid unnecessary refactors/explanations, and keep token usage highly economical while still delivering complete, testable results.
```

- Kayit politikasi: yalniz gerekli Besmele dosyalari guncellenir; handover kisa ve nettir.
- Token ekonomisi kaliteyi dusurme bahanesi degildir; az okuma ve az tekrar ile uretim seviyesi kalite korunur.

## 0) Terminoloji (MUST)

- `commit yap`: yalniz commit.
- `commit ve push yap`: once commit, sonra push.
- Commit/push notu: `<kisa-aciklama> | TASK-xxx[,TASK-yyy] | R.yymmdd_hhmm`
- `R.yymmdd_hhmm`: kanonik teslim/push isareti; kullanici yazmasa da eklenir.
- EXE dosya adina da `R.yymmdd_hhmm` eklenir.

## 1) Bismillah Tetikleyici (MUST)

- `Besmele/` veya `besmele/` varsa `bismillah` ailesi otomatik baslangictir.
- `bismillah`:
1. Repo kontrolu YAPILMAZ.
2. Yalniz `Besmele/PROTOKOL.md` ve `Besmele/STATE.md` okunur; `Besmele/ADR.md` sadece gerekirse okunur.
3. Ilk satir zorunlu: `Bismillah, Baglama alindi, calismaya hazirim.`
4. Ikinci satirda gorev/hedef sorulur.
- `bismillah kontrol` veya `bismillah kontrol et`:
1. `git fetch --prune origin`
2. `git status --short --branch`
3. `Besmele/STATE.md` okunur; `Besmele/ADR.md` sadece gerekirse okunur.
4. Once cok kisa repo ozeti verilir: `Uzak repo ile yerel repo esit.` veya `X commit onde, Y commit geride.`
5. Sonraki satir zorunlu: `Baglama alindi, calismaya hazirim.`
6. Hemen sonra gorev/hedef sorulur.

## 2) Besmele Operasyon Akisi (MUST)

- Bootstrap akisi: `Besmele/PROTOKOL.md` -> `Besmele/STATE.md`.
- Global durum/handover tek kaynagi: `Besmele/STATE.md`.
- Gorev listesi tek kaynagi: `Besmele/WORKBOARD.md`.
- Gorev listesi sorulursa `WORKBOARD.md` eksiksiz aktarilir; yoksa bu acikca belirtilir.
- Kod degisikligi oncesi yalniz ilgili `Besmele/plans/TASK-xxx.md` okunur.
- `Besmele/TOKEN_RULES.md`, `Besmele/CONVENTIONS.md`, `Besmele/ARCH_BASE.md`, `Besmele/UI_SYSTEM.md`, `Besmele/DECISIONS.md` ve `Proje/*.md` yalniz gorev dogrudan gerektiriyorsa okunur.
- Snapshot tetigi:
  - kullanici `snapshot al` derse hemen snapshot yazilir
  - arada snapshot yazilmadiysa kullanicinin 8 anlamli talimati tamamlandiginda otomatik snapshot yazilir
  - gorev degisimi, oturum kapatisi, commit/push veya `usb ye yedekle` oncesi snapshot zorunludur
- Snapshot sayaci her yeni snapshot yaziminda sifirlanir.
- Push/teslim gecmisi tek kaynagi: `Besmele/PUSH_LOG.md`.
- Push oncesi kalite kapanisi: `Besmele/QUALITY_GATE.md`.

## 3) Codex Ekip Disiplini (MUST)

- Kod degisikligi oncesi aktif gorev bulunur veya yeni `TASK-xxx` acilir.
- Her bagimsiz is icin ayri plan dosyasi zorunludur.
- `STATE.md`, `WORKBOARD.md` ve ilgili `TASK-xxx.md` birbiriyle tutarli tutulur.
- `in_progress` gorev, acik kullanici yonlendirmesi olmadan devralinmaz.
- Her anlamli devir veya push oncesi en az su dosyalar guncellenir:
  - `Besmele/STATE.md`
  - `Besmele/WORKBOARD.md`
  - ilgili `Besmele/plans/TASK-xxx.md`
  - `Besmele/PUSH_LOG.md`
- Mimari karar varsa `Besmele/ADR.md` append-only guncellenir.

## 4) Kapsam ve Minimalizm (MUST)

- Yalniz istenen kapsam degistirilir.
- Kapsam disi refactor yapilmaz.
- Cikti kisa, net, test edilebilir tutulur.
- Minimum gerekli dosya okunur; ayni bilgi tekrar yazilmaz.
- Secret/token/sifre, makineye ozel gizli bilgi ve gereksiz binary artefakt commitlenmez.
- UI duzenlemede yuzde/oran istenirse son sayisal deger yazilir; kodda carpansal ifade kullanilmaz.
- Kanonik hafiza sohbette degil repo markdown kayitlarindadir; tekrar tekrar uzun aciklama yerine delta + karar + sonraki adim yazilir.

## 5) Platform Onekleri (MUST)

- `D`: Desktop
- `W`: Web
- `M`: Mobil
- `MA`: Mobil Android
- `MI`: Mobil iOS

## 5.1) Calistirma Terminolojisi (MUST)

- `M de calistir`: emulator.
- `tel de calistir`: fiziksel telefon.
- Varsayilan: genelde `M de calistir`, genel kontrol `tel de calistir`.

## 5.2) M Calistirma Varsayilani (MUST)

- Varsayilan emulator seri no: `emulator-5554` (Pixel 7a).
- Varsayilan komut: `flutter run -d emulator-5554`.
- Seri no yoksa `adb devices` ile dogrula ve kullanicidan seri iste.
- Kalici cache icin `tools/run_m.ps1` kullan; gradle/pub cache `.cache/` altinda tutulur.

## 6) USB Bundle Yedek (MUST)

- Uzak repo yerine USB yedek tercih edilir.
- `usb ye yedekle`: `git bundle` ile tek dosya, ada `R.yymmdd_hhmm` eklenir.
- `usb den al`: bundle dosyasindan yerel repo acilir.
- `en guncelini`: en son `R.yymmdd_hhmm` etiketli bundle/teslim secilir.

## 7) ProjeOrj Arsiv (MUST)

- `ProjeOrj/` arsivdir; silinmez, guncellenmez.
- Aktif dokumanlar `Proje/` altinda tutulur.

## 8) Token Ekonomisi (Tercih)

- Gunluk tasima icin USB `.bundle` en ekonomik yoldur.
- Uzak repo push yalniz yedek/teslim amaclidir.
