# TASK-026

status: in_progress
updated: 2026-03-20 00:33 +03:00
scope: Ust panel ve vakitler paneli gorsellestirme 1. asama sonrasi cekmece yapisinin panel akisini ve ilk iskeletini kur.

done_summary:
- Vakitler paneli kulplu, suruklenebilir ust cekmece mantigina tasinacak sekilde ana ekran yapisi donusturuldu.
- Yeni nafile satiri ekleme, en dusuk bos `Nafile n` adlandirmasi, ek ikon grubunda silme ve zaman alanina dokununca acilan kural paneli icin ilk iskelet kuruldu.
- Ic ice `showTimePicker` kaynakli hata riski azaltmak icin zaman paneli ayni bottom sheet icinde saat/dakika alanlarina cekildi.
- Cekmece kulpu icin birden fazla genis chevron/V varyanti denenmeye baslandi; kullanicinin paylastigi daha derin V formu ayrica yedek tasarim adayi olarak notlandi.
- Cekmece kulpu ust panele bagli duracak sekilde ilerletildi; gereksiz alt bilgi paneli kaldirildi.
- Nafile satirlari kalici storage'a baglandi; `R`/yeniden acilista satirlar ve ozellikleri geri yukleniyor.
- Ayarlara nafilelerin vakte gore aralara girmesi veya en altta kalmasi secenegi eklendi; varsayilan aktif.
- Cekmece kulpu ikinci referans gorsele daha yakin derin `V` formuna cekildi; hit alani ve ince bar olculeri yeniden ayarlandi.

now:
- Cekmece kulpu ve ince bar boyutlari cihazda gorsel olarak son kez netlestiriliyor; eksik polish kalemleri var.

next:
- Kulp formunun son oranlarini cihazda sabitle; sonra cekmece ac-kapa davranisi, nafile kaliciligi ve siralama secenegini son kez dogrula.

refs:
- `lib/presentation/home/home_screen.dart`
