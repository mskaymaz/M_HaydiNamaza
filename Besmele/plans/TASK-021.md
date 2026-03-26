# TASK-021

status: done
updated: 2026-03-26 16:25 +03:00
scope: Telefon ADB baglantisini ve mobil calistirma akisini minimum duzeltmeyle calisir hale getir.

done_summary:
- Android SDK `platform-tools\\adb.exe` varligi dogrulandi.
- `tools/run_m.ps1` icinde `param` sirasi, Android SDK `platform-tools` PATH hazirligi ve `ANDROID_USER_HOME` cache yonlendirmesi duzeltildi.
- `tools/run_m.ps1` icinde kalan Flutter argumanlarini aktaran `FlutterArgs` destegi eklendi.
- Telefon `W4SCB69DFYEMGIAA` ve tablet `HA1GNG3P` cihazlarinda `flutter run ... --no-resident` akisi dogrulandi.
- Her iki cihazda da eski farkli imzali paket uninstall edilip guncel debug APK yeniden yuklendi.

now:
- Gorev tamamlandi; fiziksel cihaz akisi bloksuz calisiyor.

next:
- Ayni kalipla gerekirse emulator veya baska fiziksel cihazlarda `tools/run_m.ps1` kullan.

refs:
- `tools/run_m.ps1`
- `android/local.properties`
