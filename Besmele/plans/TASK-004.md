# TASK-004

Amac: Faz 2 - Flutter uygulama iskeleti ve temel mimari girisi.
Cikti:
- Flutter proje iskeleti (Android + iOS).
- Temel klasor yapisi ve ilk ekran stub.
- Ileride cok dilli yapiya uygun i18n altyapi notu.
Durum: in_progress

Notlar:
- Flutter komutlari takilma olursa dart-sdk yolu ile calistirilabilir.
- Proje adi ve paket kimligi kesinlestirilecek.
- Ikincil referans (Diyanet uyumu yok): https://www.turktakvim.com/index.php?link=html/namaz_vakitleri_nasil_hesaplanir.php (TR PDF: https://www.turktakvim.com/pdf/tr.1.pdf)
- Backlog: Haftalik/aylik/ozel tarih araligi liste + PDF/Excel/Word disa aktarim (cache tasarimi buna uygun kurulacak).
- Diyanet birebir hedefi icin veri kaynagi: https://ezanvakti.imsakiyem.com (Diyanet kaynakli API); Diyanet sayfasinda acik JSON endpoint yok.
- Ilerleme: Flutter iskeleti (Android + iOS) olusturuldu.
- Ilerleme: Klasor yapisi ve ilk ekran stub (App + HomeScreen) eklendi.
- Ilerleme: i18n altyapisi (TR/EN/AR) eklendi.
- Ilerleme: Ayarlar ekrani ve dil secimi (gecici bellek) eklendi.
- Ilerleme: Dil tercihi shared_preferences ile kalici hale getirildi.
- Ilerleme: Ayarlar ekranina konum ve hesaplama yontemi iskeleti eklendi.
- Ilerleme: Konum secimi taslagi (sehir + enlem/boylam) ve kayit eklendi.
- Ilerleme: Hesaplama yontemi listesi ve secim UI eklendi.
- Ilerleme: Secilen yontem ve konum prayer_engine ile baglandi, ana ekranda gosterim yapildi.
- Ilerleme: UI notlari derlendi, referans gorseller eklendi.
- Ilerleme: Zemin motif tercihi `img/templates_line/bg_motif02.png` olarak netlesti.
- Ilerleme: Motif renkleri (beyaz cizgi + yesil zemin) duzenlendi ve ana ekrana uygulandi.
- Ilerleme: Ana ekran ust panel kompaktlandi; baslik kaldirildi.
- Ilerleme: Liste karti bosluklari, ikon/rozet olculeri ve tipografi ayarlandi.
- Ilerleme: UI ayarlari icin merkezi `config_registry` eklendi.
- Ilerleme: Ust panelde vakit + geri sayim sag ustte; konum ikonu ve yontem satiri altinda.
- Ilerleme: UI ayarlari icin `Proje/UI_Ayarlar.md` eklendi.
- Ilerleme: Ust panel bloklari sola/saga ayrildi; konuma uzun bas ayarlar.
- Ilerleme: Konum ikonu saga alindi; gear alt satira tasindi ve saydamlasti.
- Ilerleme: Ust panel hizalamasi guncellendi; gear ustte kucuk alan, panel kucultuldu.
- Ilerleme: Dil ve hesaplama listelerinde RadioGroup gecisi yapildi.
- Ilerleme: Bos/hatali konum ekranina Ayarlar butonu eklendi.
- Ilerleme: withOpacity uyarilari withValues ile guncellendi.
- Ilerleme: solar_coordinates kullanilmayan degiskenler temizlendi.
- Ilerleme: Konum alanlari il/ilce olacak sekilde guncellendi; Diyanet odakli yapiya uygun hale getirildi.
- Ilerleme: AlAdhan API ile vakit cekme eklendi (Shafii school, method mapping, fallback local hesaplama).
- Ilerleme: Ust panelde vakit adi yanina saat eklendi; sag tarafta yontem satiri kaldirildi, gear yukariya alindi.
- Ilerleme: Ust panelde vakit saati ince ve esit boyuta alindi; alt hizalama ve padding ayarlandi.
- Ilerleme: Diyanet verisi icin ezanvakti.imsakiyem.com API’dan il/ilce cozumleme ve gunluk vakit cekme eklendi.
- Ilerleme: Diyanet/AlAdhan/calc zamanlari icin debug log eklendi.
- Ilerleme: Ayarlar->Konum icin Diyanet listeden il/ilce secimi ve favoriler eklendi.
- Ilerleme: Konum dropdown deger eslesmesi sabitlendi.
- Ilerleme: Diyanet entegrasyonu icin ayrintili debug loglar eklendi.
- Ilerleme: Diyanet vakitlerinde minute offset sifira cekildi (ham saatler).
- Ilerleme: Konum ekranina ulke listesi eklendi; countryId kaydi ve Diyanet resolve ulke bazli yapildi.
- Ilerleme: Gun degisiminde vakitleri otomatik yenileme eklendi (countdown sifirlanmasi onleme).
- Ilerleme: Sıradaki vakit geri sayimi tarih normalize edildi; favori tekrar ekleme engellendi (normalize).
- Ilerleme: Favori listesi okurken normalize dedup ve storage temizleme eklendi.
- Ilerleme: AlAdhan kaldirildi; ezanvakti tek harici kaynak.
- Ilerleme: Hesaplama yontemi listesine Aladhan eklendi.
- Ilerleme: Diyanet HTML parse denemesi eklendi (once HTML, sonra API).
- Ilerleme: Ust panel sagda tarih+saat ve tap ile miladi/hicri eklendi.
- Ilerleme: Saat buyutuldu; il/ilce title-case ve tipografi ayrildi.
- Ilerleme: Tarih+saat ortaya cekildi; gear sag/ust +10px.
- Ilerleme: Ust panel icerik dikey hizasi ortaya alindi.
- Ilerleme: Konum ikonu gear yanina tasindi; konum metni saga kaydi; panel padding azaltildi.
- Ilerleme: Gear-konum araligi azaltildi (offset ayari).
- Ilerleme: Tarih+saat sola, vakit+kalan orta hizaya alindi.
- Ilerleme: Tarih 3 satir; vakit/kalan panel ortasina alindi (stack).
- Ilerleme: Handover yedegi notu guncellendi.
- Ilerleme: Ust panel gorsel ayari olusturuldu.
