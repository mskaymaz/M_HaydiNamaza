# TASK-027

status: in_progress
updated: 2026-03-23 14:33 +03:00
scope: Mevcut `turkey` secenegine dokunmadan ayri `diyanet_tabanli` hesaplama yontemini deneysel secenek olarak ekle.

done_summary:
- Baslangic kaydi acildi.
- PrayerService icine `diyanet_tabanli` kodu eklendi; mevcut `turkey` secenegi aynen korundu.
- Ana ekran veri yukleme akisinda bu secenek icin koordinat zorunlulugu kaldirildi.
- Hesaplama yontemi secim ekranina ve ayar ozetine `Diyanet tabanli` secenegi baglandi.
- Hatirlatma dakika balonunda gereksiz bosluklar azaltildi; ikonlu onay/iptal ve 150 px genislik ayariyla sade gorunum elde edildi.
- Ayarlar panelindeki hesaplama yontemi ozeti ve secim ekrani sadeletildi; mevcut `turkey` secenegi korunurken `diyanet_tabanli` ayrik secenek olarak tutuldu.

now:
- Commit/push hazir; cihazda `diyanet_tabanli` secenegi ve hesaplama yontemi ekraninin gorunumu dogrulanacak.

next:
- `diyanet_tabanli` secildiginde vakitlerin beklendigi gibi gelip gelmedigini cihazda kontrol et.

refs:
- `lib/app/prayer_service.dart`
- `lib/presentation/settings/calculation_method_screen.dart`
- `lib/presentation/settings/settings_screen.dart`
