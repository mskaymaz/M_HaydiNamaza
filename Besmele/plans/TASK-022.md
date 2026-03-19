# TASK-022

status: done
updated: 2026-03-19 17:52 +03:00
scope: Ilk acilista bos konum yerine varsayilan Turkiye/Amasya/Merzifon yuklensin.

done_summary:
- `LocationStorage` icine varsayilan Turkiye/Amasya/Merzifon konumu eklendi.
- Kayitli kullanici konumu varsa aynen korunacak sekilde fallback yalniz bos/eksik durumlara sinirlandi.

now:
- Varsayilan konum fallback'i uygulandi.

next:
- Cihazda ilk acilis davranisini gorsel olarak dogrula.

refs:
- `lib/app/location_storage.dart`
