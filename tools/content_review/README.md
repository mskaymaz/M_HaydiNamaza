# Temporary Daily Content Review Tool

Bu klasor, Flutter uygulamasindan bagimsiz gecici bir Python inceleme aracidir.

Kapsam:
- Ayah ve hadith taslak kayitlarini tek tek gosterir.
- Kayitlari `approved`, `rejected`, `pending` olarak isaretler.
- Kaynak JSON dosyalarini degistirmez.
- Inceleme ilerlemesini ayri `review_state.json` dosyasina kaydeder.
- Cikti dosyalarini `output/` altina zaman damgali klasorlerde yazar.

## Calistirma

Repo kokunden:

```powershell
py tools/content_review/review_tool.py
```

Sonra tarayicida acin:

```text
http://127.0.0.1:8765/
```

Opsiyonel:

```powershell
py tools/content_review/review_tool.py --port 8788
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
