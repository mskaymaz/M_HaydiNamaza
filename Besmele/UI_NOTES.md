# BESMELE UI NOTLARI (Ana Ekran)

Amac: UI kararlarini tek yerde, kisa ve uygulanabilir tutmak.

## Ana gorunum
- Ust yesil panel her zaman gorunur.
- Ust panel cift tik: vakit listesi ac/kapat.
- Konum tiklaninca favori konum listesi acilir; secilene gore vakitler guncellenir.
- Opsiyonel: “sessiz mod” (tumu gecici kapat) ikonu ust panelde olabilir.
- Ust panelde uygulama adi yok; konum + geri sayim odak.
- Ust panel: sag ustte vakit adi (ustte) + geri sayim (altta); altinda konum ikonu + il-ilce, altinda yontem satiri.
- Tipografi bazlari: vakit adi 13 -> +%50 = 20, geri sayim 22 -> +%30 = 29 (sayisal sabit kullan).
- UI ayarlari icin referans: `Proje/UI_Ayarlar.md`.
- Ust panel revize: vakit + geri sayim sol blok; konum/yontem sag blok. Konuma uzun bas = ayarlar.
- Konum metni sagda, ikon metnin saginda. Gear alt satira alindi ve daha saydam.
- Ust panel hizasi: sag blok, sol vakit blogunun alt hizasina oturur; gear ustte kucuk alan.

## Vakit listesi (satir yapisi)
- Satir: vakit adi → saat → hatirlatma dakikasi → ses / goz / ezan ikonlari.
- Toggle: ikonlar tek tik aktif, tekrar tik pasif.
- Aktif vakit: satir boydan boya yesil bant (vakit degistikce kayar).
- Sonraki vakit vurgusu: GEREK YOK (kaldirildi).

## Uyari davranislari
- Sesli (TTS): vakit adi + kullanici metni, secili dilde okunur.
- Gorsel (flash/balon): ustte vakit adi, altta kullanici metni.
- Gorsel: flash konumu secilebilir veya random.
- Gorsel: ekranda kalma suresi + periyot ayarlanir.
- Durdurma:
  - Ses/gorsel tetiklenince: flash uzerinden veya ust paneldeki kirmizi kapat ile durdur.
  - Ezan baslayinca: ayri kapat butonu cikar, basinca susar.
- Ezan yakalama: vakit girdikten sonra 2 dk icinde app acilirsa ezan yine baslar.

## Ek vakitler
- Kullanici sinirsiz ekler.
- Zaman iliskisi: “ikindiye X dk kala / aksami Y dk gec” gibi.
- Isim verilir; tum uyarilar varsayilan gelir, kullanici kapatabilir.
- Silme: sadece ek vakitlerde, uzun bas → sil/ayarlar.

## Ayarlar / detay
- Uzun bas ile “Ayarla” bottom sheet (mobil uyumlu).
- Ayarlar: TTS metni, flash metni, flash konumu, sure/periyot, ezan secimi.
- Liste siralama: vakte gore sirali veya ek vakitler sonda.

## Erisilebilirlik
- Mobilde “kenardan cekme ile orantili buyutme” yerine:
  - OS text scale + uygulama “buyuk mod” (tek dugme).

## Referans Arayuz (Ana01/Ana02)
- Tema: yesil geometrik desen arkaplan + koyu kartlar.
- Ust bar: konum + hizli ayarlar ikonlari.
- Buyuk kart: “vaktine geri sayim” + tarih satiri + vakit listesi.
- Ek kartlar: “Gunun Ayeti” (baslik + metin + kaynak).
- CTA: “Aylik namaz vakitleri” butonu.
- Not: Uyelik/promosyon yok; sosyal/proje odagi.

## Zemin motif secimi
- Secilen: `img/templates_line/bg_motif02.png` (cizgiler beyaz, zemin yesil ton).

## Kible Pusulasi (Mobil)
- Ana menude “Kible” CTA; ayri ekran.
- Yontem: sensor (manyetometre + ivme) ile cihaz yonu, hesaplanan kible acisi ile fark.
- UX: buyuk pusula + sabit kible oku; aci degeri; “kalibrasyon” uyarisi.
- Kalite: sensor gurultusu icin smoothing (low-pass) ve “dogruluk” rozeti.
