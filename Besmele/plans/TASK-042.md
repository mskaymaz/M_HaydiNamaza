# TASK-042

status: done
updated: 2026-03-25 16:53 +03:00
scope: `ayetler.json` icindeki tum kayitlari karsilastir, ciftleri ayikla, kalan ayetleri sirali `ayet_NNN` id yapisina getir ve kisa durum ozeti hazirla.

done_summary:
- Dosyadaki 402 kayit tek tek ayrildi; araya karismis batch/metin parcalari ayiklanip veri tek gecerli JSON dizisine indirildi.
- Ayni `surah_number` + `ayah_number` ciftine dusen kayitlar tekilleştirildi; 101 tekrar satiri kaldirildi.
- Kalan 301 benzersiz ayet `ayet_001..ayet_301` olarak yeniden numaralandirildi.
- `text` alanlarindaki link/prompt kalintilari temizlendi ve cikis yeniden dogrulandi.

now:
- Tekilleştirme ve id yeniden siralama tamamlandi.

next:
- Gerekirse icerik dogrulugu ayet bazinda ayrica gozden gecirilebilir.

refs:
- `ayetler.json`
