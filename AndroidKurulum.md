# Android Kurulum Notlari (Kisa)

Amac: Android/Flutter kurulumunda yasanan sorunlar ve hizli cozumler.

## 0) Takim standardi
- Flutter yolu: `C:\Users\MSK\dev\flutter-git`
- Calistirma: `tools/flutter.ps1 <komut>`

## 1) Flutter komutu yok / PATH sorunu
- Belirti: `flutter` bulunamiyor.
- Cozum: `tools/flutter.ps1` kullan (PATH gerekmez).

## 2) Flutter zip kurulumunda takilma / erisim hatasi
- Belirti: `flutter.bat` uzun takiliyor veya cache yazamiyor.
- Cozum: Flutter’i git ile kur:
  - `git clone -b stable https://github.com/flutter/flutter.git C:\Users\MSK\dev\flutter-git`
  - `C:\Users\MSK\dev\flutter-git\bin\flutter.bat --version`

## 3) Android SDK yok
- Belirti: `flutter doctor` Android toolchain X.
- Cozum: Android Studio kurulumu + SDK Manager’dan:
  - SDK Platform (API 34/35/36)
  - Build-Tools
  - Command-line Tools (latest)
  - Emulator + Hypervisor Driver

## 4) Emulator offline
- Belirti: `flutter devices` emulator offline.
- Cozum: Android Studio Device Manager’dan AVD baslat.
- Gerekirse: Cold Boot / Wipe Data.

## 5) Gradle lock (buildLogic.lock)
- Belirti: “Timeout waiting to lock build logic queue”.
- Cozum: Lock tutan java surecini kapat + lock dosyasini sil:
  - PID bulun, `Stop-Process -Id <pid> -Force`
  - `android\.gradle\noVersion\buildLogic.lock` sil.

## 6) flutter_gen / l10n hatasi
- Belirti: `package:flutter_gen/...` bulunamiyor.
- Cozum:
  - `pubspec.yaml` -> `flutter: generate: true`
  - `l10n.yaml` -> `output-dir: lib/l10n`
  - Importlar: `package:mhaydinamaza/l10n/app_localizations.dart`
  - `flutter gen-l10n`

## 7) Temel calistirma
- `flutter doctor -v`
- `flutter devices`
- `flutter run -d emulator-5554`
