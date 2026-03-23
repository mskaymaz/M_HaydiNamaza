# TASK-026

status: in_progress
updated: 2026-03-23 12:54 +03:00
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
- Cekmece paneli ust panelin altina oturtuldu; alt ve ust kulp zeminleri ayni formda tutulup yalniz ok yonu degisecek sekilde polish edildi.
- Sesli hatirlatma varsayilan metni `Namaz vakti yaklaşıyor.. Haydı hazırlan...` olarak sabitlendi; bos/eski varsayilan metin kayitlari yeni metne goc ettirildi ve varsayilan periyot `15 sn` yapildi.
- Bos sesli/gorsel metinde vakit adi fallback'i korundu; gorsel karta dokunarak kapatma ve ses/gorselden biri kapatilinca titresimin de durmasi eklendi.
- Titresim tekrar araligi bagimsiz dongu olarak duzenlendi; hatirlatma suresince kullanici kapatana kadar kendi zamanlamasiyla calisacak hale getirildi.
- Ayarlar panelinde `Uygulama Dili` satiri daraltildi, yanina `Konum Ayarlari` butonu eklendi; hatirlatma secenekleri ve titresim ayarlari beyaz ayiricilarla ayrildi.
- Dakika giris balonu daha kompakt hale getirildi; yalniz veri alani ve ortalanmis onay/iptal ikonlari birakildi.
- Gorunen Turkce metinlerdeki encoding bozulmalari temizlendi; `AGENTS.md` icine `TR-UTF8-CRITICAL` kuralı eklendi.

now:
- Commit/push hazir; cihazda ayarlar paneli gorunumu ve dakika balonu dogrulamasi kaldi.

- Ayarlar paneli duzeni ve dakika balonunu cihazda son kez dogrula.

refs:
- `lib/presentation/home/home_screen.dart`
