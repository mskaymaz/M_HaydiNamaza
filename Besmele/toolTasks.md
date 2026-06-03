# toolTasks.md

Gecici dokuman.
Amac: `tool.py` icin `Incele + Ekle` panelini, gercek ayet/hadis kaynak mantigina uygun hale getirmek.
Not: Bu dosya canonical task kaynagi degildir; tasarim ve uygulama kontrol listesi icindir.

## 1. Durum ozeti

- [x] Tek panel kuruldu: `Incele` ve `Ekle`
- [x] Ayet/hadis ayrimi kuruldu
- [x] Arsiv ve minimal approved ayrimi kuruldu
- [x] Temel kaydetme, backup, undo, atomic write altyapisi kuruldu
- [x] Ekle modu calisiyor; veri cekme mantigi mevcut yerel kaynak modeline baglandi
- [x] Ayet veri akisi `Tanzil` kaynak modeline gore donusturuldu
- [x] Hadis veri akisi `Diyanet + Sunnah` kaynak modeline gore donusturuldu
- [x] Manuel test harici aktif kod maddesi kalmadi

## 2. Hedef mimari

- [x] `tool.py` sadece launcher olacak
- [x] UI ve cekirdek mantik ayrilacak
- [x] Arsiv ve approved ayri tutulacak
- [x] Ayet ve hadis icin farkli veri toplama adapterleri var
- [x] Ekle modu `tek endpoint fetch` mantigindan cikti
- [x] Ekle modu `kaynak-adapter + parser + matcher + quality + exporter` akisina gecirildi

Hedef moduller:

- [x] `tools/content_review/review_tool.py`
- [x] `tools/content_review/ui/review_panel.py`
- [x] `tools/content_review/ui/add_panel.py`
- [x] `tools/content_review/core/models.py`
- [x] `tools/content_review/core/storage.py`
- [x] `tools/content_review/core/exporters.py`
- [x] `tools/content_review/core/validators.py`
- [x] `tools/content_review/core/duplicate_checker.py`
- [x] `tools/content_review/core/backup.py`
- [x] `tools/content_review/core/logger.py`
- [x] `tools/content_review/core/fetchers/tanzil_loader.py`
- [x] `tools/content_review/core/fetchers/tanzil_ayah_provider.py`
- [x] `tools/content_review/core/fetchers/diyanet_hadith_tr_loader.py`
- [x] `tools/content_review/core/fetchers/sunnah_hadith_loader.py`
- [x] `tools/content_review/core/matchers/hadith_matcher.py`
- [x] `tools/content_review/core/quality/hadith_quality_checker.py`

## 3. Veri katmanlari

### 3.1 Arsiv

- [x] Zengin veri korunacak
- [x] Ayet arsiv yapisi Tanzil seed mantigina gore destekleniyor
- [x] Hadis arsiv yapisi Diyanet+Sunnah seed mantigina gore destekleniyor
- [x] Kaynak bilgisi acik tutuluyor
- [x] Metin depolama karari netlesti: kayitta tek asil metin tutulacak
- [x] `sourceText`, `clean`, `ttsText` gibi 3 ayri kalici metin tutulmayacak
- [x] TTS icin gereken donusum kayit aninda degil, okuma aninda uygulanacak
- [x] Tek kalan metin UTF-8 temizligi, Unicode koruma ve bosluk/satir normalizasyonu ile saklanacak
- [x] `review`, `quality`, `sourceInfo` bloklari korunuyor

### 3.2 Approved

- [x] Minimal payload korunacak
- [x] `id` kalacak
- [x] `priority` kalacak
- [x] Ayette `surah_number`, `surah_name`, `ayah_number` kalacak
- [x] Hadiste `hadith_number`, `book_reference_tr`, `book_reference_en` kalacak
- [x] Ayet/hadis approved mapleme yeni arsiv semalariyla yeniden dogrulandi

## 4. Incele modu

- [x] Mevcut arsiv kayitlarini ac
- [x] Ayet/hadis filtrele
- [x] Metinleri duzenle
- [x] Durum ve oncelik ver
- [x] Onaylayinca minimal approved'a aktar
- [x] Yeni ayet arsiv yapisindaki alternatif ceviriler gorunur
- [x] Yeni hadis arsiv yapisindaki `quality` ve `sourceInfo` bloklari gorunur
- [x] Publish/approved icinde zaten varsa gorunur sekilde goster

## 5. Ekle modu genel akis

- [x] Tur sec: `Ayet / Hadis`
- [x] Referans gir
- [x] Arsiv kontrolu yap
- [x] Approved kontrolu yap
- [x] Benzer kayit kontrolu yap
- [x] Durumlari UI'da goster
- [x] Mevcut `uzaktan cek` mantigi kaldirildi; yerel kaynak adapterleri kullaniliyor
- [x] Veri kaynagini secilen ture gore dogru adapter ile getir
- [x] Veri gelmezse mevcut panel alanlariyla kontrollu manuel giris duzenine gecilebilir
- [x] Veri hangi kaynaktan geldigi bilgisi acik gosteriliyor

## 6. Ayet veri modeli hedefi

Kaynak: `Tanzil`

- [x] Arapca kaynak: `Tanzil Uthmani Quran Text`
- [x] Turkce ana ceviri: `tr.bulac / Ali Bulac`
- [x] Turkce alternatif: `tr.diyanet / Diyanet Isleri`
- [x] Ingilizce ana ceviri: `en.sahih / Saheeh International`
- [x] Ingilizce alternatif: `en.maududi / Abul A'la Maududi`

Ayet top-level hedef yapisi:

- [x] `ref`
- [x] `id`
- [x] `surah`
- [x] `ayahStart`
- [x] `ayahEnd`
- [x] `type`
- [x] `ayahCount`
- [x] `input`
- [x] `source`
- [x] `sourceRefGroups`
- [x] `ayahs[]`
- [x] `status`
- [x] `review`

Her `ayahs[]` nesnesi:

- [x] `ref`
- [x] `surah`
- [x] `ayah`
- [x] `arabic`
- [x] `tr.main.source`
- [x] `tr.main.text`
- [x] `tr.alternative.source`
- [x] `tr.alternative.text`
- [x] `en.main.source`
- [x] `en.main.text`
- [x] `en.alternative.source`
- [x] `en.alternative.text`

## 7. Ayet ekleme akisina donusum

- [x] `sure/ayet` veya `sure/baslangic-bitis` parse et
- [x] Tekil/range yapisini ayir
- [x] Quran yapisina gore referansi dogrula
- [x] Arsivde ayni top-level ref var mi bak
- [x] Approved'da ayni minimal ref var mi bak
- [x] Gerekirse ayeti range icinde genislet
- [x] Yerel Tanzil veri dosyalarindan AR/TR/EN metinlerini bul
- [x] Ana ve alternatif cevirileri ayni anda doldur
- [x] `source` ve `input` metadata'sini doldur
- [x] `review.status = pending_review` ile arsiv kaydi uret
- [x] UI'da reviewer icin ana gosterim alanlarini doldur
- [x] Onayda minimal approved payload'a map et

## 8. Ayet kaynak hazirlik gorevleri

- [x] Tanzil veri dosyalari icin beklenen klasor yapisini tanimla
- [x] UTF-8 dosya okuma katmani ekle
- [x] Sure/ayet indexleme yapisi ekle
- [x] Range expand helper ekle
- [x] Kontrol/rapor alanlarini modele bagla
- [x] Eksik ayet veya eksik ceviri durumlarini acik hata olarak isle

## 9. Hadis veri modeli hedefi

Kaynak stratejisi:

- [x] Turkce: `Diyanet Dijital Riyazus-Salihin`
- [x] Arapca: `Sunnah.com / Sunnah-derived JSON`
- [x] Ingilizce: `Sunnah.com / Sunnah-derived JSON`
- [x] Fallback/cross-check: `IslamHouse`, `Archive.org`

Hadis hedef yapisi:

- [x] `id`
- [x] `ref`
- [x] `collection`
- [x] `hadithNo`
- [x] `topics`
- [x] `text.ar`
- [x] `text.tr`
- [x] `text.en`
- [x] `sourceInfo.tr`
- [x] `sourceInfo.ar_en`
- [x] `quality`
- [x] `review`

## 10. Hadis ekleme akisina donusum

- [x] Hadis numarasini normalize et
- [x] Arsivde ayni hadis no/ref var mi bak
- [x] Approved'da ayni hadis no/ref var mi bak
- [x] Yerel Diyanet TR kaynagindan Turkce metni bul
- [x] Yerel Sunnah JSON varsa AR+EN kaydini bul
- [x] Yerel JSON yoksa sonraki asama icin web fetch noktasi ayrildi
- [x] Once direkt hadis no ile eslestir
- [x] Gerekirse `hadithNo - 3` ile `hadithNo + 3` araliginda yakin kayit ara
- [x] `ravi + konu + anlam + kaynak referansi` sinyalleriyle eslesme ozeti uret
- [x] `quality.matchConfidence` belirle
- [x] `quality.matchStatus` belirle
- [x] Supheli durumlari `manual_review_required` olarak isaretle
- [x] `review.status = pending_review` ile arsiv kaydi uret
- [x] Onayda minimal approved payload'a map et

## 11. Hadis kalite ve eslestirme kurallari

- [x] Sadece hadis no'ya guvenme
- [x] `numberMatch` sinyali kullan
- [x] `semanticMatch` sinyali kullan
- [x] `narratorMatch` sinyali kullan
- [x] `topicMatch` sinyali kullan
- [x] Arapca Unicode gecerli mi kontrol et
- [x] Arapca PDF bozulmasi benzeri cop veri var mi kontrol et
- [x] Ingilizce bos mu kontrol et
- [x] UI/navigation coplerini temizle
- [x] Kaynak dogrulugundan suphe varsa otomatik approved yapma

Confidence seviyeleri:

- [x] `high`
- [x] `medium`
- [x] `low`
- [x] `manual_review`

Status hedefleri:

- [x] `verified_candidate`
- [x] `needs_light_review`
- [x] `manual_review_required`

## 12. TTS kurallari

- [x] Kisaltma genisletme mantigi baslatildi
- [x] Ayri `ttsText` alani tutulmayacak
- [x] TTS metni kalici veri olmayacak; tek asil metinden runtime uretilecek
- [x] Kaynak parantezleri TTS disinda tutulacak
- [x] `book_reference_tr` TTS disinda tutulacak
- [x] `book_reference_en` TTS disinda tutulacak
- [x] Arapca metindeki dini ifadeler bozulmadan korunacak

## 12A. Tek metin ve temiz saklama kurali

- [x] Her dil icin tek bir metin alani olacak
- [x] Bu alan kullaniciya gorunen asil metin olacak
- [x] Kayit sirasinda Unicode bozulmasi olusmamali
- [x] UTF-8 uyumlu saklama zorunlu olacak
- [x] `NFC` benzeri guvenli Unicode normalizasyonu uygulanabilecek
- [x] Satir sonlari tek formata getirilecek
- [x] Gereksiz BOM, kirik bosluk, fazladan satir sonu temizlenecek
- [x] Arapca karakterleri veya harekeleri bozacak agresif temizlik yapilmayacak
- [x] Turkce karakterler ASCII'ye cevrilmeyecek

## 13. UI degisiklikleri

- [x] Tum temel etiketleri Turkcelestir
- [x] Font tabani `14pt+` yap
- [x] AR/TR/EN icin yazi boyutu kontrolu ekle
- [x] Durumlari checkbox seklinde goster
- [x] Veri durumu alanini belirginlestir
- [x] Ayet range ekleme durumunu UI'da goster
- [x] Hangi kaynaktan veri geldigi ayri alan olarak goster
- [x] Hadis eslesme confidence alanini UI'da goster
- [x] Hadis `quality.notes` listesini UI'da goster
- [x] Alternatif ceviri alanlarini UI'da gorunur yap

## 14. Duplicate ve kontrol mantigi

- [x] Arsiv kontrolu
- [x] Approved kontrolu
- [x] Exact duplicate kontrolu
- [x] Possible duplicate kontrolu
- [x] Ayetlerde top-level duplicate ile ayah-level duplicate ayrimi temel duzeyde yap
- [x] Hadislerde ayni hadis no ama farkli metin durumunu ayri isaretle
- [x] Kaynak farkli ama ref ayni durumunu ayri isaretle

## 15. Export ve yazma kurallari

- [x] Backup before write
- [x] Atomic JSON write
- [x] File hash check
- [x] Undo last write
- [x] Action log
- [x] Yeni ayet arsiv semasini validate etmeden yazma
- [x] Yeni hadis arsiv semasini validate etmeden yazma
- [x] Approved payload maplerini yeni modellere gore yeniden test et

## 16. Teknik uygulama sirasi

- [x] 1: Ayet ve hadis icin kaynak-gercegi notlarini modele isle
- [x] 2: Mevcut gecici fetch mantigini `gecici/yanlis varsayim` olarak kaldir
- [x] 3: Ayet icin Tanzil loader + provider yaz
- [x] 4: Ayet range/top-level seed uretimini ekle
- [x] 5: Hadis icin Diyanet TR loader yaz
- [x] 6: Hadis icin Sunnah JSON/web loader yaz
- [x] 7: Hadis matcher + quality checker yaz
- [x] 8: UI'da yeni ayet/hadis alanlarini bagla
- [x] 9: Export maplerini yeni semalara gore duzelt
- [ ] 10: Manuel akis testi yap

## 17. Net kararlar

- [x] Ayet veri kaynagi: `Tanzil`
- [x] Hadis veri kaynagi: `Diyanet TR + Sunnah AR/EN`
- [x] Varsayilan cikti: `pending_review`
- [x] Otomatik approved yok
- [x] Arsiv yapisi zengin kalacak
- [x] Publish/approved minimal kalacak
- [x] Tanzil veri dosyalari repodaki seed dosyalarindan okunuyor
- [x] Diyanet TR veri girisi mevcut seed/json uzerinden ilerliyor
- [x] Sunnah verisi once yerel JSON/seed mantigindan okunuyor

## 17A. Kalan tek aktif asama

- [ ] Manuel akis testi yap

## 18. Manuel test listesi

- [ ] Ayet tekil ekleme
- [ ] Ayet range ekleme
- [ ] Ayet duplicate uyarisi
- [ ] Ayet eksik kaynak uyarisi
- [ ] Hadis direkt no eslesmesi
- [ ] Hadis yakin no aramasi
- [ ] Hadis dusuk confidence rozetleri
- [ ] Hadis manuel duzeltme sonrasi kaydetme
- [ ] Approved minimal export kontrolu
- [ ] TTS-disari kaynak alan kontrolu

