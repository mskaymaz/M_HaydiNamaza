# AGENTS.md

Repo: MHaydiNamaza

Bu depo icin kalici calisma kurallari.

## -1) Ekonomik Token Tetikleyici (MUST, HIGHEST PRIORITY)

- Kullanici `ekonomik token` yazdiginda veya `bismillah` dediginde, hangi asamada olunursa olunsun bu mod derhal aktif kabul edilir ve oturum sonuna kadar korunur.
- Bu tetikleyici aktifken su talimat aynen uygulanir:

```text
Work as a senior software engineer in strict minimal mode.
Prioritize production-grade quality: stable architecture, consistent UI system, performance, and backward-compatible behavior.
Apply domain-based config design (main_ui, settings_panels, help_panels, data_sources, app_behavior) with one central config_registry entry point and shared schemas for analogous UI structures.
Execute only requested scope, avoid unnecessary refactors/explanations, and keep token usage highly economical while still delivering complete, testable results.
```

## 0) Terminoloji (MUST)

- `commit yap`: Yalniz commit yapilir, push yapilmaz.
- `commit ve push yap`: Once commit, sonra push yapilir.
- Her commit/push notu su formati izler:
  - `<kisa-aciklama> | TASK-xxx[,TASK-yyy] | R.yymmdd_hhmm`
- `R.yymmdd_hhmm` ayni zamanda kanonik teslim/push isaretidir.

## 1) Bismillah Tetikleyici (MUST)

- Bu depoda `Besmele/` veya `besmele/` klasoru varsa `bismillah` ailesi otomatik baslangic tetigidir.
- `bismillah`:
1. Repo kontrolu YAPILMAZ.
2. `Besmele/PROTOKOL.md` ve `Besmele/STATE.md` okunur; gerekirse `Besmele/ADR.md` de okunur.
3. Ilk satir zorunlu olarak verilir: `Bismillah, Baglama alindi, calismaya hazirim.`
4. Hemen sonraki satirda kullanicidan gorev veya hedef istenir.
- `bismillah kontrol` veya `bismillah kontrol et`:
1. `git fetch --prune origin`
2. `git status --short --branch`
3. `Besmele/STATE.md` okunur; gerekirse `Besmele/ADR.md` de okunur.
4. Cevapta once cok kisa repo ozeti verilir:
- `Uzak repo ile yerel repo esit.` veya `X commit onde, Y commit geride.`
5. Sonraki satir zorunlu olarak: `Baglama alindi, calismaya hazirim.`
6. Hemen sonraki satirda kullanicidan gorev veya hedef istenir.

## 2) Besmele Operasyon Akisi (MUST)

- Bismillah sonrasi calisma dongusu icin tek kaynak `Besmele/PROTOKOL.md` dosyasidir.
- Global durum/handover icin tek kaynak `Besmele/STATE.md` dosyasidir.
- Gorev listesi icin tek kaynak `Besmele/WORKBOARD.md` dosyasidir.
- Her is icin kanonik plan dosyasi `Besmele/plans/TASK-xxx.md` formatindadir.
- Push/teslim gecmisi icin tek kaynak `Besmele/PUSH_LOG.md` dosyasidir.
- Push oncesi kalite kapanisi `Besmele/QUALITY_GATE.md` ile yapilir.

## 3) Codex Ekip Disiplini (MUST)

- Kod degisikligi yapmadan once aktif gorev bulunur veya yeni `TASK-xxx` plan dosyasi acilir.
- Her bagimsiz is icin ayri plan dosyasi zorunludur.
- `WORKBOARD.md`, `STATE.md` ve ilgili `TASK-xxx.md` birbirini tutmak zorundadir.
- `in_progress` durumundaki bir gorev acik kullanici yonlendirmesi olmadan devralinmaz.
- Her anlamli devir veya push oncesi en az su dosyalar guncellenir:
  - `Besmele/STATE.md`
  - `Besmele/WORKBOARD.md`
  - ilgili `Besmele/plans/TASK-xxx.md`
  - `Besmele/PUSH_LOG.md`
- Mimari karar varsa `Besmele/ADR.md` append-only guncellenir.

## 4) Kapsam ve Minimalizm (MUST)

- Sadece kullanicinin istedigi kapsami degistir.
- Kapsam disi refactor yapma.
- Ciktiyi kisa, net ve test edilebilir tut.
- Minimum gerekli dosyayi oku, minimum gerekli kaydi yaz, ayni bilgiyi gereksiz tekrar etme.
- Secret/token/sifre, yerel makineye ozel gizli bilgi ve gereksiz binary artefakt commitlenmez.

## 5) Platform Onekleri (MUST)

- Platform odakli repo/uygulama on ekleri:
- `D`: Desktop (PC/masaustu) uygulamasi
- `W`: Web uygulamasi
- `M`: Mobil uygulama (genel)
- `MA`: Mobil Android
- `MI`: Mobil iOS

## 6) USB Bundle Yedek (MUST)

- Uzak repo yerine USB uzerinden yedek tercih edilir.
- `usb ye yedekle` talimatinda `git bundle` ile tek dosya yedek alin ve dosya adina `R.yymmdd_hhmm` eklenir.
- `usb den al` talimatinda bundle dosyasindan repo acilir (yerel repo).
- `en guncelini` denince en son `R.yymmdd_hhmm` etiketli bundle/teslim secilir.

## 7) ProjeOrj Arsiv (MUST)

- `ProjeOrj/` klasoru arsivdir: silinmez ve icerigi guncellenmez.
