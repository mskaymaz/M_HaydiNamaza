# TASK-008

Amac: Kisisellestirme ve ileri hesaplama ayarlari.
Cikti:
- Hesaplama metodu, madhab, yuksek enlem, shafaq, rounding ve ofset ayarlari.
- Favori konumlar ve hizli gecis.
- Ayarlarin kalici saklanmasi ve prayer_engine entegrasyonu.
Durum: done

Notlar:
- Mevcut calculation_method_storage ile uyumlu.

Kapanis (2026-03-30 14:44 +03:00):
- Hesaplama metodu ekrani ileri ayarlarla genisletildi: madhab, yuksek enlem, shafaq, rounding, vakit ofsetleri.
- Ayarlar kalici saklandi: `calculation_advanced_settings_storage`.
- Prayer engine entegrasyonu tamamlandi: `PrayerService` bu ayarlari parametrelere uygular ve cache fingerprint'e dahil eder.
- Favori konumlar ve hizli gecis mevcut akisla korunuyor (Settings/Location ekranlari).
