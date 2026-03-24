# TASK-036

status: done
updated: 2026-03-24 15:26 +03:00
scope: `ayetkarsilastir.md` icindeki `Metin` alanlarini `Sure No + Ayet No` bazli eslestirerek yeni bir `ayetler_guncel.json` dosyasi olustur.

done_summary:
- Yeni dosyanin mevcut `ayetler.json` yerine gecmeden ayri adla uretilmesi kararlastirildi.
- `ayetkarsilastir.md` icindeki `Metin` alanlari regex ile cikartildi.
- Eslesme `Sure No + Ayet No` anahtariyla yapildi.
- `72/72` kayit eslesti ve yeni `ayetler_guncel.json` dosyasi olusturuldu.
- MD icindeki trailing markdown kaynak baglari `text` alanina tasinmadi.

now:
- Cikti hazir; commit/push yapiliyor.

next:
- Eslesen kayit sayisini dogrula.
- Gerekirse fark raporu ver.

refs:
- `ayetler.json`
- `ayetkarsilastir.md`
