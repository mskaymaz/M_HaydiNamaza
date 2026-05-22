# Temporary Daily Content Review Tool (PySide6 Desktop)

Bu klasor, Flutter uygulamasindan bagimsiz gecici bir Python masaustu inceleme aracidir.

Kapsam:
- Ayah ve hadith taslak kayitlarini tek tek masaustu pencerede gosterir.
- JSON kod yapisini ekranda gostermez; odakli inceleme paneli sunar.
- Teknik bilgileri (tur, sure/hadis bilgisi, numara, kaynak notu) ayri alanda gosterir.
- Turkce, Arapca, Ingilizce metinleri ayri panellerde gosterir.
- Kayitlari `approved`, `backlog`, `pending` olarak isaretler (UI: Onaylandi / Arkaya At / Beklet).
- Oncelik alani sabit listeden secilir (`normal`, `important`, `high`, `seasonal`, `hidden`).
- Metin alanlari duzenlendikce ve butonlarla durum verildikce degisiklikler aninda kaydedilir.
- Ust panelden ID ile hizli kayda atlama yapilabilir (`ID'ye Git`).
- `Sonraki Pending` ile sadece bekleyen kayitlara hizli gecis yapilabilir.
- Kaynak JSON dosyalarini dogrudan gunceller (varsayilan: `publish/ayetler.json` ve `publish/hadisler.json`).
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
Varsayilan kaynaklar: `Besmele/data/daily_panel/publish/ayetler.json` ve `Besmele/data/daily_panel/publish/hadisler.json`.

Istersen dogrudan tek grupla baslatabilirsin:

```powershell
py tools/content_review/review_tool.py --dataset ayah
py tools/content_review/review_tool.py --dataset hadith
```

Opsiyonel:

```powershell
py tools/content_review/review_tool.py --ayah "D:\path\ayetler.json" --hadith "D:\path\hadisler.json"
```

## Kayit Dosyalari

- Inceleme durumu: `tools/content_review/review_state.json`
- Ciktilar: `tools/content_review/output/review_export_YYYYMMDD_HHMMSS/`
  - `approved.json`
  - `rejected.json` (backlog)
  - `pending.json`
  - `review_decisions.json`

## Guvenlik Notu

- Kaynak dosyalar dogrudan guncellenir; ilk yazimda ayni klasorde `.bak.YYYYMMDD_HHMMSS` yedegi olusur.
- Cikti klasoru her export'ta yeni olusturulur; var olan export klasoru ezilmez.
- State dosyasi atomik yazim ile guncellenir (`.tmp` -> replace).

## Is Bitince Silme

Bu arac gecicidir. Gerektiginde tumuyle kaldirmak icin:

```powershell
Remove-Item -Recurse -Force tools/content_review
```
