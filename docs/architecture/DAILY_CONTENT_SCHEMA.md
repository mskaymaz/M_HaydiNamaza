# Daily Content Schema (TASK-05 Checkpoint 2)

Bu dokuman, TASK-05 veri temeli icin ayet/hadis JSON sozlesmesini tanimlar.

## Klasor ayrimi

- `assets/data/daily_content/approved/`
  - Uygulamanin runtime'da okuyacagi tek klasordur.
  - UI'da yalnizca bu klasorden gelen ve `status: "approved"` olan kayitlar gosterilecektir.
- `assets/data/daily_content/draft/`
  - Taslak calisma klasoru. Runtime okumasi yoktur.
- `assets/data/daily_content/archive/`
  - Arsiv klasoru. Runtime okumasi yoktur.

## Genel JSON yapisi

Her dosya su ust alanlari icerir:

- `schema_version` (zorunlu, string)
- `content_version` (zorunlu, string)
- `type` (zorunlu, `ayah` veya `hadith`)
- `records` (zorunlu, dizi)

Her kayitta su alanlar zorunludur:

- `id` (string)
- `type` (string)
- `status` (string, bu fazda beklenen deger: `approved`)
- `approval` (obje)
  - `approved_by` (string)
  - `approved_at` (ISO-8601 string)
  - `review_note` (string)

## Ayah kayit alanlari

Zorunlu alanlar:

- `id`
- `type` (`ayah`)
- `surah_name`
- `surah_number`
- `ayah_number`
- `text`
- `translation`
- `meal_source`
- `source_note`
- `topics` (string dizi)
- `status`
- `approval`

## Hadith kayit alanlari

Zorunlu alanlar:

- `id`
- `type` (`hadith`)
- `collection`
- `book`
- `hadith_number`
- `narrator`
- `text`
- `translation`
- `grade`
- `source_note`
- `topics` (string dizi)
- `status`
- `approval`

## Dil ve icerik notu

- Uygulamada kullaniciya gosterilecek metinler Turkce olacaktir.
- Bu checkpointteki JSON dosyalari ornek veridir; final dini icerik veri seti degildir.

