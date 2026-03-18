# TASK-004

status: in_progress
updated: 2026-03-18 09:56 +03:00
scope: Faz 2 - Flutter uygulama iskeleti ve temel mimari girisi.

done_summary:
- Iskelet hazir: Flutter proje (Android + iOS), klasor yapisi, `App`/`HomeScreen`, i18n (TR/EN/AR).
- Ayarlar hazir: dil kaliciligi, konum ve hesaplama panelleri, Diyanet odakli ulke/il/ilce secimi, favoriler.
- Veri akisi hazir: `ezanvakti.imsakiyem.com` birincil kaynak, HTML parse denemesi, gunluk vakit cekme, normalize/dedup ve debug loglar.
- UI temeli hazir: merkezi `config_registry`, ust panel yerlesimi, tarih 3 satir, vakit/kalan merkez, konum gear alti.
- Stabilite iyilestirmeleri hazir: gun degisimi yenileme, countdown tarih normalize, storage temizleme, `withValues` gecisi.

now:
- Uygulamada kalinan nokta: ust panel gorsel ayari olusturuldu; tarih 3 satir, vakit/kalan merkez, konum gear alti.

next:
- 00:00 gun gecisinde vakitlerin otomatik yenilendigini dogrula.
- Paket adi/proje kimligi netlesince kalici adlandirmayi sabitle.

refs:
- `Proje/UI_Ayarlar.md`
- `Besmele/ADR.md`
