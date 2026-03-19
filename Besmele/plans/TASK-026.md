# TASK-026

status: in_progress
updated: 2026-03-19 23:04 +03:00
scope: Ust panel ve vakitler paneli gorsellestirme 1. asama sonrasi cekmece yapisinin panel akisini ve ilk iskeletini kur.

done_summary:
- Vakitler paneli kulplu, suruklenebilir ust cekmece mantigina tasinacak sekilde ana ekran yapisi donusturuldu.
- Yeni nafile satiri ekleme, en dusuk bos `Nafile n` adlandirmasi, ek ikon grubunda silme ve zaman alanina dokununca acilan kural paneli icin ilk iskelet kuruldu.
- Ic ice `showTimePicker` kaynakli hata riski azaltmak icin zaman paneli ayni bottom sheet icinde saat/dakika alanlarina cekildi.

now:
- Cekmece davranisi ve yeni satir akislarinin cihazda gercek gorunumu/davranisi dogrulaniyor; eksik polish kalemleri var.

next:
- Cekmece handle gorunumu, ac-kapa davranisi ve nafile satiri/zaman paneli akislarini cihazda netlestirip tamamla.

refs:
- `lib/presentation/home/home_screen.dart`
