# TASK-004

status: in_progress
updated: 2026-03-19 11:03 +03:00
scope: Faz 2 - Flutter uygulama iskeleti ve temel mimari girisi.

done_summary:
- Iskelet hazir: Flutter proje (Android + iOS), klasor yapisi, `App`/`HomeScreen`, i18n (TR/EN/AR).
- Ayarlar hazir: dil kaliciligi, konum ve hesaplama panelleri, Diyanet odakli ulke/il/ilce secimi, favoriler.
- Veri akisi hazir: `ezanvakti.imsakiyem.com` birincil kaynak, HTML parse denemesi, gunluk vakit cekme, normalize/dedup ve debug loglar.
- UI temeli hazir: merkezi `config_registry`, ust panel yerlesimi, tarih 3 satir, vakit/kalan merkez, konum gear alti.
- Stabilite iyilestirmeleri hazir: gun degisimi yenileme, countdown tarih normalize, storage temizleme, `withValues` gecisi.
- Konum ekrani sadeleştirildi: kompakt dropdownlar, bas harfi buyuk ad gosterimi, koordinat satiri ve favori yonetimi eklendi.
- Ayarlar ekraninda `Favori Konumlar` ve dil secimi dropdown yapisina alindi; konum ozeti tek bosluklu `il / ilce` ve alt satir koordinat olacak sekilde normalize edildi.
- Konum ekraninda `Favori Konumlar` bolumu `Favorilere ekle` butonunun altina tasindi.
- Android tarafinda `INTERNET` izni eklendi; fiziksel telefonda Diyanet konum listelerinin veri cekebilmesi saglandi.
- Konum ekranindaki favori dropdownu ayarlar ekraniyla uyumlu hale getirildi; secim sonrasi ayri `Uygula` ve `Sil` aksiyonlari eklendi.
- Mobil uygulama adi Android ve iOS tarafinda `Haydi Namaza` olarak guncellendi.
- Konum ekranindaki favori aksiyonlari dar mobil genislikte kaybolmasin diye dropdown altindaki ayri aksiyon satirina tasindi.
- Ayarlar ve konum ekranlarindaki favori satiri yeniden esitlenildi; iki tarafta da dropdown + `Uygula` + `Sil` ayni kompakt tek satir stiline cekildi.
- Telefon tarafinda bos gelen ulke/il/ilce listeleri icin Diyanet istekleri `Accept: application/json` ve timeout ile guclendirildi; konum ekranina gorunur hata ve `Tekrar dene` akisi eklendi.
- Prayer service tarafindaki Diyanet istekleri de ayni istek basliklari ve timeout ile esitlenildi.
- Diyanet secim akisinda enlem-boylam zorunlulugu kaldirildi; koordinatlar bos olsa da konum kaydi ve favori uygulama akisi devam ediyor.
- Ayarlar ekraninda `Mevcut Konumu Al` checkbox'i eklendi; cihaz konumu izinle alinip il/ilce ve koordinatlar otomatik dolduruluyor.
- Ana panelde sol ust konum ozeti tiklanabilir hale getirildi ve dogrudan konum ekranina baglandi.
- `Mevcut Konumu Al` checkbox'i konum ekranina tasindi; reverse geocode timeout'u ham exception yerine yumusak uyariya cevrildi.
- Favori dropdownlari kapali durumdayken mevcut konum ozetini gosterecek sekilde guncellendi.
- Mola/backup oncesi snapshot alindi; mevcut durum backup devrine hazir.
- `Ayarlar ve Arayuz duzenlemesi devam ediyor` notuyla commit/push hazirlandi.
- `E:\\M_HaydiNamaza_R.260318_1645.bundle` bundle yedegi olusturuldu.
- Konum ekranindaki favori `Uygula` aksiyonu ikinci `Kaydet` adimini gerektirmeyecek sekilde dogrudan kaydet + donus yapacak hale getirildi.
- Codex devri icin mevcut durum snapshot kaydi alindi.
- Ana panel tekrar duzeltildi; konum en ustte tek satir, tarih ve saat solda iki satir, orta vakit-kalan bloku konum satirinin altina alindi.
- `R.260318_1659` etiketiyle bundle yedek oncesi yeni snapshot alindi.
- Ust panel son turda tamamlandi: konum satiri yatay merkezde, ilce ince tipte, gear ayni satirda saga tasinip buyutuldu; tarih-saat solda serbest ve `Siradaki Vakit` blogu sanal `1/3-2/3` hesabiyla sag alana merkezlendi.
- Ayarlar sadeleştirildi; favori konum ve konum sec kisimlari kaldirildi, hesaplama yontemi uste tasindi.
- Ayarlar icine panel/yazi ve arka plan zemin/cizgi renk secicileri eklendi; palette ana panel, Vakitler Paneli, ayar panelleri ve geometrik background'a baglandi.
- Background motifi ustten 15 px bosluk birakacak sekilde asagi alindi; renk basliklarina bilgi ikonu ve reset aksiyonlari eklendi.

now:
- Uygulamada kalinan nokta: zemin ve panel renklendirme tamamlandi; commit/push hazir.

next:
- Renk duzenlemelerini cihazda gorsel olarak dogrula.
- Ust panel yerlesimini cihazda gorsel olarak dogrula.
- USB bagli telefonda konum dropdownlarinin acildigini kontrol et.
- Ayarlar ve konum ekranlarinda favori satirinin tek satir gorunumunu ve `Uygula`/`Sil` akislarini cihazda dogrula.
- Mobil cihazda uygulama adinin `Haydi Namaza` olarak gorundugunu kontrol et.
- Telefon uzerinde ulke, il ve ilce listelerinin artik yuklendigini dogrula.
- Telefonda il/ilce secip koordinatlar bosken kaydetme ve ana ekranda Diyanet vakitlerinin gelmesini dogrula.
- Telefonda `Mevcut Konumu Al` checkbox'ini isaretleyip izin ve otomatik konum dolumunu dogrula.
- Telefonda reverse geocode timeout'unda ham exception yerine yumusak mesaj geldigini dogrula.
- Backup/yedek adimini tamamla.
- Telefonda ana panelde konum tek satir, sol tarih-saat ve orta vakit bloku yerlesimini dogrula.
- `E:` surucusune `R.260318_1659` etiketli bundle yedegini yaz.

refs:
- `Proje/UI_Ayarlar.md`
- `Besmele/ADR.md`
