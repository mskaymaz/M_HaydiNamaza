# TASK-021

status: blocked
updated: 2026-03-19 17:52 +03:00
scope: Telefon ADB baglantisini ve mobil calistirma akisini minimum duzeltmeyle calisir hale getir.

done_summary:
- Android SDK `platform-tools\\adb.exe` varligi dogrulandi.
- Telefonun ADB tarafinda `unauthorized` oldugu netlesti.
- `tools/run_m.ps1` icinde `param` sirasi, Android SDK `platform-tools` PATH hazirligi ve `ANDROID_USER_HOME` cache yonlendirmesi duzeltildi.

now:
- Cihaz trust eslesmesi telefon tarafinda tamamlanmadan fiziksel telefonda calistirma bloklu.

next:
- Telefonda USB debugging authorizations sifirla ve yeniden onayla.
- `flutter run -d W4SCB69DFYEMGIAA`

refs:
- `tools/run_m.ps1`
- `android/local.properties`
