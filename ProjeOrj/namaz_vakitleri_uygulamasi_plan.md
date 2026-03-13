# Profesyonel Namaz Vakitleri Uygulaması

## Flutter (iOS + Android) -- Ürün, Mimari ve Geliştirme Planı

Bu doküman profesyonel seviyede bir **namaz vakitleri uygulaması**
geliştirmek için hazırlanmış kapsamlı bir teknik plan içerir.

Amaç: - Güvenilir - Hızlı - Offline çalışabilen - Estetik -
Kişiselleştirilebilir - Dünya çapında kullanılabilir

bir mobil uygulama geliştirmektir.

------------------------------------------------------------------------

# 1. Ürün Vizyonu

Amaç yalnızca vakit göstermek değildir.

Amaç:

**Güvenilir, hızlı ve sade bir ibadet zaman platformu oluşturmak.**

Hedef özellikler:

-   Doğru vakit hesaplama
-   Offline çalışma
-   Düşük batarya tüketimi
-   Temiz ve huzurlu arayüz
-   Çoklu dil desteği

------------------------------------------------------------------------

# 2. Teknoloji Stack

Framework:

Flutter 3.x+

Minimum Platform:

Android 8+\
iOS 13+

State Management:

Riverpod

Dependency Injection:

get_it

Local Database:

Isar

Notifications:

flutter_local_notifications

Localization:

intl

Location:

geolocator\
geocoding

Routing:

auto_route

Model Generation:

freezed

------------------------------------------------------------------------

# 3. Clean Architecture

Proje mimarisi:

Clean Architecture + Feature Based

    lib/

    core/
      constants
      theme
      localization
      utils
      errors

    features/
      prayer_times
      location
      notifications
      settings
      onboarding

    shared/
      widgets
      components
      services

    data/
    domain/
    presentation/

------------------------------------------------------------------------

# 4. Faz Yol Haritası

## Faz 0 --- Ürün Tanımı

Belirlenecekler:

-   Minimum OS
-   Desteklenen diller
-   Hesaplama metodu
-   Gizlilik politikası

Diller:

-   Türkçe
-   İngilizce
-   Arapça

------------------------------------------------------------------------

## Faz 1 --- Namaz Vakti Hesaplama Motoru

Core Engine:

Astronomik hesaplama sistemi

Hesaplanan vakitler:

-   Fajr
-   Sunrise
-   Dhuhr
-   Asr
-   Maghrib
-   Isha

Core kütüphane:

    core/prayer_engine

Dosya yapısı:

    prayer_engine/

    calculation_method.dart
    solar_calculator.dart
    julian_date.dart
    prayer_times.dart
    coordinates.dart

------------------------------------------------------------------------

## Faz 2 --- Konum Sistemi

Konum seçenekleri:

1 GPS\
2 Şehir arama\
3 Manuel koordinat

Favori konumlar desteklenecek.

------------------------------------------------------------------------

## Faz 3 --- Veri Katmanı

Offline-first yaklaşım

Akış:

API → Repository → Cache → UI

------------------------------------------------------------------------

## Faz 4 --- UI / UX

Temel ekranlar:

1 Onboarding\
2 Ana ekran\
3 Vakit listesi\
4 Konum seçimi\
5 Ayarlar

------------------------------------------------------------------------

# 5. Ana Ekran Tasarımı

    -----------------------------

    Current Prayer

    Maghrib
    18:42

    Remaining
    00:25:31

    Next Prayer
    Isha

    -----------------------------

    Fajr
    Sunrise
    Dhuhr
    Asr
    Maghrib
    Isha

    -----------------------------

    Location
    Istanbul

    -----------------------------

------------------------------------------------------------------------

# 6. Bildirim Sistemi

Bildirim türleri:

-   Namaz vakti bildirimi
-   Ön hatırlatma
-   Cuma hatırlatması

Kullanıcı ayarları:

-   5 dk önce
-   10 dk önce
-   15 dk önce

Opsiyonel:

Adhan sesi

------------------------------------------------------------------------

# 7. Performans Hedefleri

App launch:

\< 1.5 saniye

RAM kullanımı:

\< 120 MB

------------------------------------------------------------------------

# 8. Erişilebilirlik

Desteklenecek:

-   Large text
-   Screen reader
-   High contrast
-   Color blind support

------------------------------------------------------------------------

# 9. Test Stratejisi

Unit Test:

Core calculation engine

Integration Test:

-   location
-   database
-   notifications

Test şehirleri:

-   Istanbul
-   Mecca
-   Cairo
-   London
-   New York
-   Jakarta

365 gün test

------------------------------------------------------------------------

# 10. CI/CD

Pipeline:

GitHub Actions

Steps:

-   lint
-   test
-   build
-   deploy

Deployment:

fastlane

------------------------------------------------------------------------

# 11. Flutter Proje Klasör Yapısı

    lib/

    app/
      app.dart
      router.dart

    core/
      theme
      constants
      utils
      localization

    features/

      prayer/
        data/
        domain/
        presentation/

      location/
        data/
        domain/
        presentation/

      notifications/
        data/
        domain/
        presentation/

      settings/
        presentation/

    shared/

      widgets
      components
      services

------------------------------------------------------------------------

# 12. Prayer Engine Tasarımı

Algoritma bileşenleri:

Solar Position Calculation

Julian Date

Declination

Equation of Time

Solar Angle

Asr shadow calculation

Parametreler:

-   Latitude
-   Longitude
-   Timezone
-   Calculation Method

------------------------------------------------------------------------

# 13. UI Wireframe Planı

Ana ekran

Vakit listesi

Konum ekranı

Favori konumlar

Ayarlar

Bildirim ayarları

Tema ayarları

Dil ayarları

------------------------------------------------------------------------

# 14. UX Ekran Listesi

Toplam yaklaşık ekran sayısı:

40+

Örnekler:

Onboarding

Welcome

Location Permission

Choose Language

Home

Prayer Details

Location Search

Favorite Locations

Notification Settings

Theme Settings

Calculation Method

Offsets

About App

Privacy Policy

------------------------------------------------------------------------

# 15. Gelecek Özellikler

Kıble pusulası

Ramazan modu

İftar / sahur

Camii bul

Kuran entegrasyonu

Widget desteği

------------------------------------------------------------------------

# 16. Proje Tahmini

Kod boyutu:

25.000 -- 40.000 satır

Geliştirme süresi:

1 geliştirici:

3--5 ay

2 geliştirici:

2--3 ay

------------------------------------------------------------------------

# 17. Hedef

Dünya çapında kullanılabilecek:

Modern\
Minimal\
Güvenilir

bir namaz vakitleri uygulaması geliştirmek.
