# Ayet / Hadis / Fıkıh İçerik Promptları

## Ayet Veri Üretim Promptu

```text
Türkçe bir mobil uygulama için kısa, güvenilir ve kart gösterimine uygun ayet meali veri seti hazırlıyorsun.

Amaç:
Kullanıcıya günlük gösterilecek kısa ayet içerikleri üretmek. Metinler sade, anlaşılır, insanı doğruluğa, İslam’a, güzel ahlaka ve bilinçli yaşamaya çağıran nitelikte olsun.

Öncelikli konu tercihleri:
- cihad
- devlet yönetimi
- insani ilişkiler
- prensipli hayat yaşama
- İslam’a bağlılık
- kardeşliğe bağlılık
- ümmet bilinci
- ahlaklı olma
- büyüklere ve küçüklere davranış
- peygamberlerin sözlerine itibar edilmesi
- doğruluğa çağırma
- İslam’a çağırma
- insanlığa faydalı olma

Kural:
- Önce bu konu başlıklarına en uygun ayetleri seç.
- Eğer birebir uygun ayet bulmak zorsa, bu temalara en yakın ayetlerle devam et.
- Aynı konuya yığılma yapma; mümkün olduğunca dengeli dağıt.
- Ayetler kısa, güçlü ve mobil kartta gösterilebilir olsun.
- Çok uzun ayetler seçme.
- Uydurma ayet, yanlış sure/ayet numarası veya belirsiz kaynak üretme.
- Emin olmadığın kaydı ekleme.

Çıktı kuralları:
- Sadece geçerli JSON array döndür.
- Markdown kullanma.
- Açıklama, giriş, kapanış, not, başlık yazma.
- Kod bloğu kullanma.
- Türkçe karakterleri düzgün kullan.
- Her kayıt tekil olsun.
- language alanı her zaman "tr" olsun.
- status alanı her zaman "draft" olsun.
- Bu mesajda tam 50 kayıt üret.
- Numara sıralaması {{START_NO}} değerinden başlasın ve artarak devam etsin.
- Sonraki kullanıcı mesajında devam istenirse kaldığın yerden numaralandırmayı sürdür.

Kritik tekrar engeli:
- Aşağıdaki hariç listesi veya mevcut veri setinde bulunan hiçbir sure/ayet yeniden üretilmesin.
- Aynı sure/ayet referanslı hiçbir varyant, paraphrase, kısaltılmış hal veya yeniden yazılmış versiyon üretilmesin.
- Üretilen yeni kayıtlar da kendi içinde birbirini tekrar etmesin.

Metin kalitesi:
- `text` alanı doğal ve akıcı Türkçe meal olsun.
- `text_short` alanı 1 cümlelik kısa özet olsun.
- `title` alanı ayetin ana mesajını kısa ve güçlü versin.
- `topic` alanı seçilen ana temayı tek kısa ifade ile yazsın.
- `tags` alanı 2 ila 4 kısa etiket içersin.

JSON şeması:
[
  {
    "id": "ayet_{{NNN}}",
    "type": "ayet",
    "topic": "string",
    "title": "string",
    "text": "string",
    "text_short": "string",
    "source_note": "SureAdı Sûresi, X. ayet | Meal: Diyanet",
    "tags": ["string", "string"],
    "language": "tr",
    "status": "draft",
    "surah_name": "string",
    "surah_number": 0,
    "ayah_number": 0,
    "meal_source": "Diyanet"
  }
]

Numaralandırma kuralı:
- Eğer {{START_NO}} = 1 ise ilk kayıt `ayet_001` olsun.
- Eğer {{START_NO}} = 51 ise ilk kayıt `ayet_051` olsun.
- Eğer {{START_NO}} = 73 ise ilk kayıt `ayet_073` olsun.
- Üç haneli sıfır dolgulu format kullan.

Şimdi {{START_NO}} numarasından başlayarak 50 kayıt üret.
```

## Hadis Veri Üretim Promptu

```text
Türkçe bir mobil uygulama için kısa, güvenilir ve kart gösterimine uygun hadis veri seti hazırlıyorsun.

Amaç:
Kullanıcıya günlük gösterilecek kısa hadis içerikleri üretmek. Metinler sade, anlaşılır, güvenilir kaynaklı, güzel ahlaka, namaza, doğruluğa, kardeşliğe, sabra, merhamete, ilme, helal-haram hassasiyetine ve bilinçli yaşamaya çağıran nitelikte olsun.

Öncelikli konu tercihleri:
- namaz
- doğruluk
- ihlas
- kardeşlik
- ümmet bilinci
- güzel ahlak
- büyüklere ve küçüklere davranış
- merhamet
- sabır
- ilim
- dua
- kul hakkı
- helal-haram hassasiyeti
- insanlara faydalı olma
- İslam’a bağlılık ve sünnete ittiba

Kaynak güvenilirliği kuralı:
- Önceliği Buhârî ve Müslim’de geçen rivayetlere ver.
- Gerekirse Tirmizî, Ebû Dâvûd, Nesâî ve İbn Mâce’deki yaygın ve güvenilir rivayetleri kullan.
- Kaynağından emin olmadığın, numarasını doğrulayamadığın veya sıhhatinden şüphe ettiğin kaydı ekleme.
- Uydurma söz, zayıf olduğu açıkça bilinen rivayet veya kaynağı belirsiz metin üretme.
- Aynı rivayetin farklı koleksiyonlardaki tekrarlarını ayrı kayıt gibi çoğaltma.

Metin kuralları:
- `text` alanı doğal ve akıcı Türkçe anlam/çeviri olsun.
- `text_short` alanı 1 cümlelik kısa özet olsun.
- `title` alanı hadisin ana mesajını kısa ve güçlü versin.
- `topic` alanı seçilen ana temayı tek kısa ifade ile yazsın.
- `tags` alanı 2 ila 4 kısa etiket içersin.
- Çok uzun rivayetler seçme; mobil kartta rahat gösterilebilecek içerikleri tercih et.
- Arapça metin verme; yalnız Türkçe içerik üret.
- Türkçe karakterleri düzgün kullan.

Çıktı kuralları:
- Sadece geçerli JSON array döndür.
- Markdown kullanma.
- Açıklama, giriş, kapanış, not, başlık yazma.
- Kod bloğu kullanma.
- Her kayıt tekil olsun.
- `language` alanı her zaman `"tr"` olsun.
- `status` alanı her zaman `"draft"` olsun.
- Bu mesajda tam 50 kayıt üret.
- Numara sıralaması `{{START_NO}}` değerinden başlasın ve artarak devam etsin.
- Sonraki kullanıcı mesajında devam istenirse kaldığın yerden numaralandırmayı sürdür.

Kritik tekrar engeli:
- Aşağıdaki hariç listesi veya mevcut veri setinde bulunan hiçbir hadis yeniden üretilmesin.
- Aynı rivayetin kısaltılmış, sadeleştirilmiş, yeniden yazılmış veya başka koleksiyon referanslı varyantını tekrar üretme.
- Üretilen yeni kayıtlar da kendi içinde birbirini tekrar etmesin.

JSON şeması:
[
  {
    "id": "hadis_{{NNN}}",
    "type": "hadis",
    "topic": "string",
    "title": "string",
    "text": "string",
    "text_short": "string",
    "source_note": "Buhârî, İman, 7 | Çeviri: sadeleştirilmiş Türkçe",
    "tags": ["string", "string"],
    "language": "tr",
    "status": "draft",
    "narrator": "string",
    "collection": "string",
    "book": "string",
    "chapter_or_topic": "string",
    "hadith_number": "string",
    "grade": "sahih"
  }
]

Numaralandırma kuralı:
- Eğer `{{START_NO}} = 1` ise ilk kayıt `hadis_001` olsun.
- Eğer `{{START_NO}} = 51` ise ilk kayıt `hadis_051` olsun.
- Eğer `{{START_NO}} = 73` ise ilk kayıt `hadis_073` olsun.
- Üç haneli sıfır dolgulu format kullan.

Şimdi `{{START_NO}}` numarasından başlayarak 50 kayıt üret.
```

## Fıkhi Mesele Veri Üretim Promptu

```text
Türkçe bir mobil uygulama için kısa, güvenilir ve kart gösterimine uygun fıkhi mesele veri seti hazırlıyorsun.

Amaç:
Kullanıcıya günlük gösterilecek kısa fıkhi mesele içerikleri üretmek. Metinler sade, anlaşılır, güvenilir, amel edilebilir ve bilinçli yaşamayı destekleyen nitelikte olsun.

Öncelikli konu tercihleri:
- cihad
- İslam Devleti kurma
- halife ve emire itaat
- devlet malına karşı hassasiyet
- ümmet bilinci
- namaz
- doğruluk
- ihlas
- kardeşlik
- güzel ahlak
- büyüklere ve küçüklere davranış
- merhamet
- sabır
- ilim
- dua
- kul hakkı
- helal-haram hassasiyeti
- insanlara faydalı olma
- İslam’a bağlılık ve sünnete ittiba

Kaynak ve güvenilirlik kuralı:
- Yalnızca yaygın, güvenilir ve yerleşik sünni fıkıh/ilmihal bilgisi düzeyinde meseleler üret.
- Açık ihtilaf bulunan konularda bunu kesin ve tek görüş gibi sunma.
- Mezhebe göre değişen meselelerde bunu kısa ve net biçimde belirt.
- Kaynağından emin olmadığın, yanlış yönlendirme riski taşıyan veya slogan gibi duran içerik üretme.
- Uydurma hüküm, belirsiz nakil veya aşırı kesin ifade kullanma.

Metin kuralları:
- `text` alanı doğal ve akıcı Türkçe olsun.
- Metinler mümkün olduğunca kısa, öz ve hızlı okunur olsun.
- Kullanıcı uzun açıklama okumayacağı için gereksiz detay, tekrar ve uzatılmış girişlerden kaçın.
- Fıkhi mesele bir hükmü, şartı ve sınırı kısa biçimde anlatmalı.
- Uzun vaaz, makale veya ders anlatımı gibi yazma.
- `text_short` alanı 1 cümlelik kısa özet olsun.
- `title` alanı meselenin ana fikrini kısa ve güçlü versin.
- `topic` alanı seçilen ana temayı tek kısa ifade ile yazsın.
- `tags` alanı 2 ila 4 kısa etiket içersin.
- Türkçe karakterleri düzgün kullan.

Çıktı kuralları:
- Sadece geçerli JSON array döndür.
- Markdown kullanma.
- Açıklama, giriş, kapanış, not, başlık yazma.
- Kod bloğu kullanma.
- Her kayıt tekil olsun.
- `language` alanı her zaman `"tr"` olsun.
- `status` alanı her zaman `"draft"` olsun.
- Bu mesajda tam 50 kayıt üret.
- Numara sıralaması `{{START_NO}}` değerinden başlasın ve artarak devam etsin.
- Sonraki kullanıcı mesajında devam istenirse kaldığın yerden numaralandırmayı sürdür.

Kritik tekrar engeli:
- Aynı fıkhi meseleyi farklı başlıkla tekrar üretme.
- Aynı hükmün sadeleştirilmiş, yeniden yazılmış veya benzer varyantını ayrı kayıt yapma.
- Üretilen yeni kayıtlar kendi içinde de tekrar etmesin.

JSON şeması:
[
  {
    "id": "fikih_{{NNN}}",
    "type": "fikih",
    "topic": "string",
    "title": "string",
    "text": "string",
    "text_short": "string",
    "source_note": "Genel ilmihal özeti | Kaynak çizgisi: güvenilir sünni fıkıh literatürü",
    "tags": ["string", "string"],
    "language": "tr",
    "status": "draft",
    "fiqh_category": "string",
    "hukm_level": "farz|vacip|sünnet|mubah|mekruh|haram|ihtilaflı",
    "school_scope": "genel|cumhur|hanefi|şafii|maliki|hanbeli|ihtilaflı"
  }
]

Numaralandırma kuralı:
- Eğer `{{START_NO}} = 1` ise ilk kayıt `fikih_001` olsun.
- Eğer `{{START_NO}} = 51` ise ilk kayıt `fikih_051` olsun.
- Eğer `{{START_NO}} = 73` ise ilk kayıt `fikih_073` olsun.
- Üç haneli sıfır dolgulu format kullan.

Şimdi `{{START_NO}}` numarasından başlayarak 50 kayıt üret.
```

## Bilgilendirme Paneli Mimari Notu

- Kapsam: ayet, hadis ve fikhi mesele içerikleri bilgi panelinde gösterilecek.
- İlk tercih: `local-first` yapı.
- İçerikler uygulama ile birlikte yerel gelir; ilk açılışta hazır olur.
- Günlük/random seçim cihaz içinde yapılır.
- Görsel, foto ve ses eki planlanmaz; metin + kaynak odaklı ilerlenir.
- Panel tipleri büyük oranda renk farkı ile ayrışır.
- İleride yeni içerikler için sürümlü uzak içerik paketi güncellemesi eklenebilir.
- İçerik akışı: `GPT taslak -> manuel/editoryal kontrol -> onaylı veri -> uygulama`.
