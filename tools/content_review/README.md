# Temporary Daily Content Review Tool (PySide6 Desktop)

Bu klasor, Flutter uygulamasindan bagimsiz gecici bir Python masaustu inceleme aracidir.

Kapsam:
- Ayah ve hadith taslak kayitlarini tek tek masaustu pencerede gosterir.
- JSON kod yapisini ekranda gostermez; odakli inceleme paneli sunar.
- Teknik bilgileri (tur, sure/hadis bilgisi, numara, kaynak notu) ayri alanda gosterir.
- Turkce, Arapca, Ingilizce metinleri ayri panellerde gosterir.
- Kayitlari `approved`, `rejected`, `pending` olarak isaretler.
- Oncelik alani sabit listeden secilir (`normal`, `important`, `high`, `seasonal`, `hidden`).
- Save / Onceki / Sonraki islemleri mevcut kayit kararini aninda `review_state.json` dosyasina yazar.
- Kaynak JSON dosyalarini degistirmez.
- Inceleme ilerlemesini ayri `review_state.json` dosyasina kaydeder.
- Cikti dosyalarini `output/` altina zaman damgali klasorlerde yazar.

## Gereksinim

PySide6 kurulumu:

```powershell
py -m pip install PySide6
```

## Calistirma

Repo kokunden:

```powershell
py tool.py
```

veya dogrudan:

```powershell
py tools/content_review/review_tool.py
```

Komut, yerel bir masaustu pencere acar.

Opsiyonel:

```powershell
py tools/content_review/review_tool.py --ayah "D:\path\ayahs_draft.json" --hadith "D:\path\hadiths_draft.json"
```

## Kayit Dosyalari

- Inceleme durumu: `tools/content_review/review_state.json`
- Ciktilar: `tools/content_review/output/review_export_YYYYMMDD_HHMMSS/`
  - `approved.json`
  - `rejected.json`
  - `pending.json`
  - `review_decisions.json`

## Guvenlik Notu

- Kaynak dosyalar salt-okunur kullanilir.
- Cikti klasoru her export'ta yeni olusturulur; var olan export klasoru ezilmez.
- State dosyasi atomik yazim ile guncellenir (`.tmp` -> replace).

## Is Bitince Silme

Bu arac gecicidir. Gerektiginde tumuyle kaldirmak icin:

```powershell
Remove-Item -Recurse -Force tools/content_review
```
