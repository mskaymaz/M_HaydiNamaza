# TASK-005

Amac: UI/UX temel ekranlar, navigasyon ve tasarim sistemi.
Cikti:
- Tema, tipografi, renk, spacing ve temel komponentler.
- Ana ekran (mevcut/sonraki vakit vurgusu + geri sayim).
- Vakit listesi, konum ozeti, ayarlar/konum/hesaplama ekranlarina navigasyon.
- Erisilebilirlik temel kontrolleri (text scale, semantics, RTL hazirligi).
Durum: done

Notlar:
- Mevcut Home/Settings iskeleti uzerinden ilerle.
- Tasarimlar global kullanima uygun sadelikte olacak.

Kapanis (2026-03-30 13:54 +03:00):
- Tasarim sistemi: `lib/core/config/config_registry.dart` (main_ui, settings_panels, data_sources, app_behavior).
- Ana ekran + sonraki vakit + geri sayim: `lib/presentation/home/home_screen.dart`.
- Navigasyon: Home -> Settings -> Location/Calculation ekran gecisleri aktif.
- Erisilebilirlik temel hazirlik: locale secimi + `ar` locale destegi ile RTL hazirligi ve varsayilan metin olcekleme davranisi mevcut.
