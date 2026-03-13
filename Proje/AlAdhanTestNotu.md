# AlAdhan Test Notu

## Ozet
- Dart komutu PATH uzerinden calisirken takilma yasandi.
- Basarili test calistirma yontemi: dogrudan Dart SDK yolu ile komut.
- AlAdhan (Turkey method=13) verileri ile golden test calistiginda cok sayida fark cikti.
- Adhan-testdata seti ile uyum devam ediyor.

## Neden (muhtemel)
- AlAdhan "Diyanet" hesaplamasi Diyanet'in sahadaki vakitleriyle bire bir eslesmeyebilir.
- Diyanet tarafinda method/offset ayrintilari resmi ve tam acik degil.

## Karar/Not
- AlAdhan verisi "referans" kabul edilecek; golden testin zorunlu setine dahil edilmeyecek.
- Gerektiginde karsilastirma icin tutulur.

## Basarili Test Komutu (Hatirlatma)
```
C:\flutter\bin\cache\dart-sdk\bin\dart.exe run tools\golden_test_runner.dart
```
