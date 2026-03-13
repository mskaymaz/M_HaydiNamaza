# Altin Test Seti Formati

## Format (JSON Array)
Her kayit bir test vektoru:
- id: benzersiz
- city: isim
- lat, lon: koordinatlar
- timezone: IANA timezone (ornek: Europe/Istanbul)
- utc_offset_minutes: opsiyonel, test calismasi icin acik ofset
  - Not: DST/IANA cozumlenemeyen kayitlar atlanir.
- date: YYYY-MM-DD
- method: hesaplama yontemi (enum)
- madhab: shafi | hanafi
- high_latitude_rule: middle_of_the_night | seventh | twilight_angle
- adjustments: dakikalik ofsetler (fajr, sunrise, dhuhr, asr, maghrib, isha)
- times: beklenen saatler (HH:mm)
- source: referans etiketi (adhan-testdata)

## Ornek
```json
[
  {
    "id": "ist-2026-03-13-mwl-shafi",
    "city": "Istanbul",
    "lat": 41.0082,
    "lon": 28.9784,
    "timezone": "Europe/Istanbul",
    "date": "2026-03-13",
    "method": "MWL",
    "madhab": "shafi",
    "high_latitude_rule": "middle_of_the_night",
    "adjustments": {"fajr":0,"sunrise":0,"dhuhr":0,"asr":0,"maghrib":0,"isha":0},
    "times": {"fajr":"05:10","sunrise":"06:35","dhuhr":"12:58","asr":"16:20","maghrib":"19:12","isha":"20:32"},
    "source": "adhan-testdata"
  }
]
```

## Ilk Kapsam Listesi
- Ankara
- Doha
- Dubai
- Kuwait City
- London
- Makkah
- Singapore
- Tehran
