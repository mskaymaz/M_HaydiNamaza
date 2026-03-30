# TASK-006

Amac: Konum, timezone/DST ve offline-first veri katmani.
Cikti:
- GPS, sehir arama ve manuel koordinat akisi.
- Timezone/DST cozumleme ve saklama.
- Prayer times repository + cache/yenileme kurallari.
- Veri kaynagi tercihi ve yedekleme stratejisi notu.
Durum: done

Notlar:
- Kullanici konumu ve hesaplama parametreleri tek kaynaktan.
- Offline-first oncelikli.
- Backlog: 30 gunluk vakit cache + favori eklenince prefetch.
- Backlog: Liste ekranlari (haftalik/aylik/ozel tarih araligi) ve disa aktarim (PDF/Excel/Word) icin veri katmani altyapisi.

Kapanis (2026-03-30 14:08 +03:00):
- Konum akisleri: GPS + sehir secimi + manuel koordinat akisi mevcut yapida korundu (`location_screen`).
- Timezone/DST saklama: `LocationStorage` icine `timeZoneName` ve `timeZoneOffset` alanlari eklendi.
- Repository/cache: `PrayerService` icinde gunluk offline-first cache eklendi (`prayer_daily_cache_v1`).
- Yenileme kurali: gun/method/konum/timezone fingerprint degisirse taze hesap; ayni gun/eslesen fingerprintte cache kullan.
- Veri kaynagi tercihi + yedekleme: `turkey`/`diyanet_tabanli` icin once Diyanet, basarisizsa local prayer engine fallback.

Delta (2026-03-30 14:24 +03:00):
- `turkey`/`diyanet_tabanli` fallback zinciri genisletildi:
  1) Diyanet
  2) Aladhan `turkey` (Diyanet yapisi)
  3) Aladhan `turkey` + `shafii`
  4) local prayer engine
