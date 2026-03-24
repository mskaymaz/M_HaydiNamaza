# BESMELE ADR

- 2026-03-15: UI ayarlari icin merkezi `config_registry` ve domain bazli config bolumleri eklendi.
- 2026-03-17: Diyanet vakit ve konum verisi icin `ezanvakti.imsakiyem.com` API kullanimi (ulke/sehir/ilce + prayer-times); Diyanet sayfasinda acik JSON endpoint yok.
- 2026-03-18: Besmele bootstrap akisi `STATE -> gerekirse WORKBOARD -> ilgili TASK` olarak sikistirildi; plan dosyalarinda snapshot/ozet formati benimsendi.
- 2026-03-18: M_HaydiNamaza Besmele omurgasi, `BesmeleUltra` ilkeleriyle sentezlendi; cekirdek bootstrap ekonomik kalirken uygulama-ozel UI/mimari dokumanlari opsiyonel referans katmanina alindi.
- 2026-03-24: Bilgilendirme paneli (ayet/hadis/fikhi mesele) icin `local-first` icerik mimarisi benimsendi; icerikler uygulama ile birlikte yerel gelir, gunluk secim cihazda yapilir, ileride surumlu uzak icerik paketleriyle guncelleme eklenebilir.
