# MHaydiNamaza - Calisma Yapisi ve Plan (Ozet)

## Amac
- Mobil platformlarda (Flutter) dogru, hizli, offline calisabilen ve guvenilir namaz vakitleri uygulamasi gelistirmek.

## Besmele Entegrasyon Notu
- Bu dokuman urun planinin kisa ozetidir. Operasyonel takip ve handover icin Besmele/PROTOKOL.md, Besmele/STATE.md, Besmele/WORKBOARD.md ve ilgili Besmele/plans/TASK-xxx.md dosyalari temel kaynaktir.

## Kapsam Kararlari (Netlestirilecek)
- Minimum Android ve iOS surumleri.
- Varsayilan hesaplama metodu.
- Veri kaynaklari listesi (birincil ve yedek).
- Dil hedefleri (TR, EN, AR vb.).
- Bildirim varsayilan davranislari ve kullanici ayarlari.
- Gizlilik politikasi ve izin metinleri.

## I18n Notu
- Baslangicta i18n altyapisi kurulacak (string anahtarlari, locale dosyalari, RTL destegi, tarih/sayi formatlari) ki yeni diller eklenmesi sadece icerik isine insin.

## Calisma Yapisi (Is Paketleri)
- Algoritma Portu ve Altin Test Seti.
- Zaman/Konum Altyapisi (timezone, DST, manuel/otomatik konum).
- Veri Katmani ve Offline/Online Kurallari.
- Bildirim ve Ses Altyapisi (ezan, TTS, test modu).
- UI/UX ve Ekran Akislari.
- Performans, Batarya, Hata Izleme.
- CI/CD, Store Hazirligi ve Sürümleme.

## Faz Plani (Kisa)
- Faz 0: Kapsam, hedef kitle, platform min surumleri, veri kaynaklari, dil listesi.
- Faz 1: Python algoritmanin Dart portu ve altin test seti.
- Faz 2: Veri katmani, cache, offline/online kurallari, timezone/DST.
- Faz 3: Temel UI, navigasyon, erisilebilirlik, tema.
- Faz 4: Bildirim, alarm, sesli okuma, arka plan kurallari.
- Faz 5: Kisisellestirme, hesaplama metodu, ofsetler, favoriler.
- Faz 6: Performans, batarya, bellek, hata yakalama.
- Faz 7: Dagitim, CI/CD, store hazirligi, release notlari.
- Faz 8: Operasyon, guncelleme stratejisi, geri bildirim toplama.

## Teslimatlar
- Uygun mimari iskeleti ve modul yapisi.
- Algoritma motoru + test paketi.
- Offline-first veri katmani.
- Bildirim ve ses altyapisi.
- Uygulama ekranlari ve akislari.
- Store dokumanlari (gizlilik, izin, release notlari).

## Konsolide Ozet (Kaynaklardan)
- Teknoloji: Flutter 3.x, Riverpod, get_it, Isar, flutter_local_notifications, intl, geolocator, geocoding, auto_route, freezed.
- Mimari: Clean Architecture + feature-based; data/domain/presentation katmanlari.
- Hesaplama motoru: Julian Date, solar declination, equation of time, solar angle, Asr shadow, method/offset parametreleri.
- Bildirimler: vakit bildirimi, on hatirlatma, Cuma; varsayilan 5/10/15 dk; opsiyonel ezan.
- Ekranlar: onboarding, ana ekran, vakit listesi, konum secimi, ayarlar, bildirim/tema/dil ayarlari; toplam 40+ ekran hedefi.
- Erişilebilirlik: large text, screen reader, high contrast, color blind support.
- Performans: acilis < 1.5 sn, RAM < 120 MB hedefi.
- Test: engine unit test; location/db/notifications integration test; test sehirleri (Istanbul, Mekke, Kahire, Londra, New York, Jakarta).
- CI/CD: GitHub Actions (lint/test/build/deploy), fastlane.
- Gelecek: kibla pusulasi, Ramazan modu, iftar/sahur, cami bul, Kuran, widget.
- Tahmin: 25k-40k LOC; 1 dev 3-5 ay, 2 dev 2-3 ay.

## Acik Sorular (Oncelik)
- Minimum iOS/Android surumleri?
- Varsayilan hesaplama metodu?
- Veri kaynaklari listesi?
- Dil hedefleri?
- Bildirim varsayilani ve kullanici ayarlari?
