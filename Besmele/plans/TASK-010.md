# TASK-010

Amac: Performans, batarya ve hata izleme.
Cikti:
- Acilis sureci hedefleri ve profil raporu.
- Hesaplama ve cache optimizasyonlari.
- Crash/error izleme entegrasyonu (pluggable).
Durum: done

Notlar:
- Hedefler: hizli acilis, dusuk RAM.

Kapanis (2026-03-30 15:01 +03:00):
- Acilis sureci profil izi eklendi: ilk frame suresi debug log (`startup_first_frame_ms`).
- Hesaplama/cache optimizasyonu: `PrayerService` icine bellek ici cache katmani eklendi.
- Pluggable hata izleme: `RuntimeMonitor` + degistirilebilir `ErrorReporter` arabirimi eklendi.
- Guvenli yaklasim: mevcut islevsel akis degistirilmedi, yalniz izleme/olcum katmani eklendi.
