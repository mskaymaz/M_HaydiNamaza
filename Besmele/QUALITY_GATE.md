# BESMELE QUALITY_GATE

- Testler calisti mi?
- Temel akislarda regresyon var mi?
- Surumleme ve notlar hazir mi?
- Kapsam yalniz istenen isle sinirli mi?
- `STATE`, `WORKBOARD` ve ilgili `TASK` kayitlari tutarli mi?
- Mimari karar veya yeni kural varsa `ADR`/`DECISIONS` guncellendi mi?
- Secret veya gereksiz artefakt var mi?

## 2026-03-13 00:52 +03:00
- Testler calisti mi? Hayir (calistirilmadi).
- Temel akislarda regresyon var mi? Bilinmiyor (degisiklik yok, repo init).
- Surumleme ve notlar hazir mi? Evet (push log guncellenecek).

## 2026-03-15 22:25 +03:00
- Testler calisti mi? Hayir (calistirilmadi).
- Temel akislarda regresyon var mi? Bilinmiyor (emulator onayi bekleniyor).
- Surumleme ve notlar hazir mi? Evet (push log guncellendi).

## 2026-03-17 00:50 +03:00
- Testler calisti mi? Hayir (calistirilmadi).
- Temel akislarda regresyon var mi? Bilinmiyor (dokuman guncellemesi).
- Surumleme ve notlar hazir mi? Evet (push log guncellendi).

## 2026-03-18 14:17 +03:00
- Testler calisti mi? Hayir (dokuman entegrasyonu; kod/test calistirilmasi gerekmedi).
- Temel akislarda regresyon var mi? Hayir (yalniz operasyon markdown omurgasi guncellendi).
- Surumleme ve notlar hazir mi? Evet (`STATE`, `WORKBOARD`, `TASK-016`, `ADR` ve `PUSH_LOG` senkron guncellendi).

## 2026-03-18 14:27 +03:00
- Testler calisti mi? Hayir (yalniz markdown snapshot ve push hazirligi).
- Temel akislarda regresyon var mi? Hayir (kod degisikliklerine dokunulmadi).
- Surumleme ve notlar hazir mi? Evet (`STATE`, `PUSH_LOG`, `TASK-016` ve diger ilgili Besmele kayitlari push oncesi hizalandi).

## 2026-03-19 09:47 +03:00
- Testler calisti mi? Hayir (calistirilmadi).
- Temel akislarda regresyon var mi? Bilinmiyor (ust panel yerlesimi cihazda dogrulanmadi).
- Surumleme ve notlar hazir mi? Evet (`STATE`, `WORKBOARD`, `TASK-004` ve `PUSH_LOG` guncellendi).

## 2026-03-19 10:08 +03:00
- Testler calisti mi? Hayir (calistirilmadi).
- Temel akislarda regresyon var mi? Hayir (yalniz preflight metni kisaltildi).
- Surumleme ve notlar hazir mi? Evet (`STATE`, `WORKBOARD`, `TASK-019` ve `PUSH_LOG` guncellendi).

## 2026-03-19 11:03 +03:00
- Testler calisti mi? Hayir (calistirilmadi).
- Temel akislarda regresyon var mi? Bilinmiyor (renk duzenlemeleri cihazda dogrulanmadi).
- Surumleme ve notlar hazir mi? Evet (`STATE`, `WORKBOARD`, `TASK-004` ve `PUSH_LOG` guncellendi).

## 2026-03-19 14:12 +03:00
- Testler calisti mi? Hayir (`dart analyze` zaman asimina girdi; cihaz derleme dogrulamasi kullanici tarafinda yapildi/parcali ilerledi).
- Temel akislarda regresyon var mi? Bilinmiyor (hatirlatma donguleri ve qibla ekrani cihazda yeniden tam dogrulanmadi).
- Surumleme ve notlar hazir mi? Evet (`STATE`, `WORKBOARD`, `TASK-004` ve `PUSH_LOG` guncellendi).

## 2026-03-19 14:19 +03:00
- Testler calisti mi? Hayir (yalniz vakit satiri yerlesimi duzeltildi; ek test calistirilmadi).
- Temel akislarda regresyon var mi? Bilinmiyor (ikon merkezleme cihazda yeniden dogrulanmadi).
- Surumleme ve notlar hazir mi? Evet (`STATE`, `WORKBOARD`, `TASK-004` ve `PUSH_LOG` guncellendi).

## 2026-03-19 17:52 +03:00
- Testler calisti mi? Kismen (`flutter pub get` tamamlandi; `flutter build apk --debug` timeout verse de `build/app/outputs/flutter-apk/app-debug.apk` uretildi).
- Temel akislarda regresyon var mi? Bilinmiyor (telefon/emulator dogrulamasi tamamlanmadi; ADB hala `unauthorized`).
- Surumleme ve notlar hazir mi? Evet (`STATE`, `WORKBOARD`, `TASK-021`..`TASK-024` ve `PUSH_LOG` guncellendi).

## 2026-03-19 22:15 +03:00
- Testler calisti mi? Hayir (`dart format` ve `flutter analyze` denemeleri timeout oldu; son duzenlemeler manuel ilerledi).
- Temel akislarda regresyon var mi? Bilinmiyor (vakitler paneli ve qibla ikon duzeni cihazda yeniden dogrulanmadi).
- Surumleme ve notlar hazir mi? Evet (`STATE`, `WORKBOARD`, `TASK-025`, `TASK-026` ve `PUSH_LOG` guncellendi).

## 2026-03-19 23:04 +03:00
- Testler calisti mi? Kismen (kullanicidan `flutter run` derleme hatasi geri bildirimi alindi; hedefli duzeltme yapildi ama `dart analyze`/`dart format` yine timeout oldu).
- Temel akislarda regresyon var mi? Bilinmiyor (cekmece davranisi ve yeni nafile satiri akislarinin cihaz dogrulamasi tamamlanmadi).
- Surumleme ve notlar hazir mi? Evet (`STATE`, `WORKBOARD`, `TASK-026` ve `PUSH_LOG` guncellendi).

## 2026-03-20 00:33 +03:00
- Testler calisti mi? Hayir (cihaz geri bildirimiyle iteratif duzenleme yapildi; ek test/analyze calistirilmadi).
- Temel akislarda regresyon var mi? Bilinmiyor (cekmece kulpu oranlari ve nafile siralama davranisi cihazda son kez dogrulanmadi).
- Surumleme ve notlar hazir mi? Evet (`STATE`, `WORKBOARD`, `TASK-026` ve `PUSH_LOG` guncellendi).

## 2026-03-23 11:48 +03:00
- Testler calisti mi? Kismen (kullanici tarafinda `dart format`, parcali `flutter analyze` ve cihazda iteratif `r/R` kontrolleri yapildi; tam proje testi calistirilmadi).
- Temel akislarda regresyon var mi? Bilinmiyor (cekmece gorunumu ve titresim dongusu cihazda son kez yeniden dogrulanacak).
- Surumleme ve notlar hazir mi? Evet (`STATE`, `WORKBOARD`, `TASK-026` ve `PUSH_LOG` guncellendi).

## 2026-03-23 12:54 +03:00
- Testler calisti mi? Hayir (son tur duzenleme sonrasi commit/push oncesi yeniden test calistirilmadi).
- Temel akislarda regresyon var mi? Bilinmiyor (ayarlar paneli ve dakika balonu cihazda yeniden dogrulanacak).
- Surumleme ve notlar hazir mi? Evet (`STATE`, `WORKBOARD`, `TASK-026` ve `PUSH_LOG` guncellendi).

## 2026-03-24 13:42 +03:00
- Testler calisti mi? Hayir (yalniz markdown prompt kaydi eklendi).
- Temel akislarda regresyon var mi? Hayir (uygulama koduna dokunulmadi).
- Surumleme ve notlar hazir mi? Evet (`STATE`, `WORKBOARD`, `TASK-028` ve `PUSH_LOG` guncellendi).

## 2026-03-24 14:09 +03:00
- Testler calisti mi? Hayir (yalniz backlog/plans markdown kayitlari guncellendi).
- Temel akislarda regresyon var mi? Hayir (uygulama koduna dokunulmadi).
- Surumleme ve notlar hazir mi? Evet (`STATE`, `WORKBOARD`, `TASK-029`..`TASK-032` ve `PUSH_LOG` guncellendi).

## 2026-03-24 14:22 +03:00
- Testler calisti mi? Hayir (yalniz bilgilendirme paneli karar kayitlari guncellendi).
- Temel akislarda regresyon var mi? Hayir (uygulama koduna dokunulmadi).
- Surumleme ve notlar hazir mi? Evet (`STATE`, `WORKBOARD`, `TASK-033`, `ADR` ve `PUSH_LOG` guncellendi).

## 2026-03-24 15:20 +03:00
- Testler calisti mi? Hayir (veri dosyasi eslestirme ve yeni JSON cikisi; kod/test calistirilmasi gerekmedi).
- Temel akislarda regresyon var mi? Hayir (uygulama koduna dokunulmadi).
- Surumleme ve notlar hazir mi? Evet (`STATE`, `WORKBOARD`, `TASK-034`..`TASK-036` ve `PUSH_LOG` guncellendi).
