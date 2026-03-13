# TASK-003

Amac: Faz 1 - Adhan tabanli hesaplama cekirdegi + altin test seti hazirligi.
Cikti:
- Adhan kaynak/lisans notu (referans secimi).
- Dart tarafi prayer_engine modul iskeleti (core/prayer_engine).
- Altin test seti formati ve ilk kapsam listesi.
Durum: in_progress

Notlar:
- Online API yok; hesaplama cihazda.
- Test seti sehir/tarih/yontem/sonuc yapisini sabitleyecek.
- Kaynak notu: Proje/AdhanKaynakNotu.md
- Test seti formati: Proje/AltinTestSetiFormati.md
- Ilk veri dosyalari: testdata/adhan/*.json (adhan-testdata/Times tabanli)
- Ilerleme: lib/core/prayer_engine/* iskeleti ve tools/golden_test_runner.dart eklendi.
- Ilerleme: Adhan-js hesaplama cekirdegi Dart portu (astronomical/solar_time/prayer_times).
