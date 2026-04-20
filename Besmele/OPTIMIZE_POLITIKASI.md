# OPTIMIZE POLITIKASI

Amac: Sislik yapan talimat ve `md` yapilarini mimari seviyeyi, kapsam gucunu ve etki alanini dusurmeden guvenli bicimde konsolide etmek.

## Temel Kural
- `optimize` komutu kalitenin yerine kisalik koymaz.
- Mimari seviye dusuyorsa, kapsam zayifliyorsa veya etki alani belirsizlesiyorsa hicbir sey uygulamaz.
- Gerekirse sonuc `uygun optimize yok` olabilir.

## Dokunulmayan Alanlar
- `STATE.md`
- `Besmele/HISTORY.md`
- aktif `TASK` dosyalari
- kullanicinin acikca korunmasini istedigi talimat ve hafiza dosyalari

## Hedef Alanlar
- tekrar eden kural metinleri
- ayni amaci tasiyan daginik rehberler
- eski ama artik referans olarak degerini kaybetmis yardimci talimatlar
- tek kaynak yerine kopya bilgi tasiyan `md` yapilari

## Komut Davranisi
- `optimize`: adaylari, riskleri ve beklenen kazanci listeler.
- `optimize uygula`: yalniz guvenli ve onayli konsolidasyonu uygular.
- `optimize derin`: daha ileri seviyede birlestirme onerir; guc kaybi riski varsa yalniz raporla durur.

## Cikti Beklentisi
- hangi dosyalar ana kaynak kalacak
- hangi dosyalar birlesecek veya arsive aday
- neden bu konsolidasyonun guvenli oldugu
- neden uygun optimize bulunamadiysa bunun kisa gerekcesi

Ne zaman acilir?
- Talimat ve `md` yapilarinda sislik oldugu dusunuldugunde ama mimari kaliteyi dusurmeden sadeleştirme istendiginde.
