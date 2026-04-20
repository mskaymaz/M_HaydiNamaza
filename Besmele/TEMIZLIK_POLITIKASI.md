# TEMIZLIK POLITIKASI

Amac: Repo sismesine yol acan uretilmis veya gecici artefaktlari guvenli bicimde temizlemek; gecmise, hafizaya ve kaynak dosyalara zarar vermemek.

## Temel Kural
- Temizlik yalniz uretilmis, gecici, yeniden olusturulabilir varliklarla ilgilenir.
- `git` gecmisi, tracked kaynak dosyalar, `md` talimatlari ve task hafizasi varsayilan olarak korunur.
- Supheli dosyalar otomatik silinmez; aday liste olarak sunulur.

## Guvenli Aday Gruplari
- `paket`: `.bundle`, `.zip`, `.apk`, `.aab`, `.ipa`, `.exe`, `.msi`
- `build`: `build/`, `dist/`, `out/`, `release/`, `public_release/`, `staging/`
- `cache`: `__pycache__/`, `.pytest_cache/`, `.dart_tool/`, `.next/`, `.turbo/`
- `gecici`: export, gecici rapor, yeniden uretilmis yerel cikti dosyalari

## Dokunulmayan Alanlar
- `AGENTS.md`, `CORE.md`, `STATE.md`
- `Besmele/` altindaki kural, hafiza ve plan dosyalari
- Repo icindeki tracked kaynak kod ve aktif konfig dosyalari
- Kullanici onayi olmayan task, roadmap, handover ve benzeri hafiza dosyalari

## Komut Davranisi
- `temizle`: Adaylari ve tahmini alan kazancini listeler.
- `temizle liste`: Yalniz rapor verir, silme yapmaz.
- `temizle uygula`: Guvenli adaylari temizler.
- `temizle derin`: Daha genis temizlik icin ek oneri veya onay ister.

## Raporlama
- Temizlik sonrasi en az su ozet verilir:
- kac dosya ve klasor temizlendi
- yaklasik ne kadar alan acildi
- hangi alanlara dokunulmadi
- onay bekledigi icin atlanan supheli adaylar

Ne zaman acilir?
- Repo sismesini azaltmak, eski artefaktlari temizlemek veya `temizle` komutunun sinirlarini anlamak gerektiginde.
