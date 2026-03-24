# TASK-034

status: done
updated: 2026-03-24 14:53 +03:00
scope: `ayetler.json` dosyasini teknik olarak gecerli, tek parca ve kullanima hazir JSON haline getir; icerik tekrarlarini raporla.

done_summary:
- Dosyanin 40 adet 10'lu JSON blogu ve aradaki not satirlariyla yapistirildigi tespit edildi.
- `id` dizisi `ayet_001`..`ayet_400` araliginda tam ve sirasiyla mevcut.
- Teknik sorun: dosya tek parca JSON olmadigi icin dogrudan parse edilemiyor.
- JSON bloklari birlestirilip dosya tek array olarak yeniden yazildi.
- Icerik sorunu: 400 kayit icinde yalniz 72 benzersiz sure/ayet cifti var; ayni kaynagin cok sayida tekrar ettigi goruldu.

now:
- Teknik temizlik tamamlandi; tekrar raporu hazir.

next:
- Tekrar eden ayetleri benzersiz icerikle degistir veya bu veri setini daha sonra ikinci turdan gecir.

refs:
- `ayetler.json`
