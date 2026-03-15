# UI AYARLAR

Amac: UI ayarlarini tek yerden, sayisal ve izlenebilir tutmak.

Kaynak dosya:
- `lib/core/config/config_registry.dart`

Notlar:
- Yuzde/oran istenirse deger hesaplanir ve sayisal sabit yazilir. Kodda carpansal ifade kullanilmaz.

## Ana ekran (main_ui)

`ConfigRegistry.mainUi`

- `screenPadding`: ekran kenar bosluklari.
- `topPanelPadding`: ust panel ic bosluklari.
- `sectionGap`: ust panel ile liste arasindaki bosluk.
- `settingsIconSize`: ayar ikonu boyutu.
- `settingsIconBoxSize`: ayar ikonunun dokunma alani.
- `settingsIconOpacity`: ayar ikonunun gorunurluk opakligi.
- `topPanel`: renk, radius, golge.
- `listPanel`: liste karti rengi, radius, golge.
- `listPadding`: liste karti ic bosluklari.
- `rowGap`: satir ici ikon/rozet araliklari.
- `iconToggle`: ikon buton boyutu + ikon size + arka plan/radius.
- `reminderChip`: rozet boyutu + font size + arka plan/border.
- `typography`: metin boyutlari (konum, yontem, vakit adi, geri sayim, liste).

## Degisim yaklasimi

1. UI istegini sayisal hedefe cevir.
2. `config_registry.dart` icindeki ilgili sabiti degistir.
3. Emulatorda hot restart yapip onay al.
