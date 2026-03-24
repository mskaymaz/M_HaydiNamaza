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
- Üç haneli sıfır dolgulu format kullan.

Şimdi {{START_NO}} numarasından başlayarak 50 kayıt üret.
```

## Bilgilendirme Paneli Mimari Notu

- Kapsam: ayet, hadis ve fikhi mesele icerikleri bilgi panelinde gosterilecek.
- Ilk tercih: `local-first` yapi.
- Icerikler uygulama ile birlikte yerel gelir; ilk acilista hazir olur.
- Gunluk/random secim cihaz icinde yapilir.
- Gorsel, foto ve ses eki planlanmaz; metin + kaynak odakli ilerlenir.
- Panel tipleri buyuk oranda renk farki ile ayrisir.
- Ileride yeni icerikler icin surumlu uzak icerik paketi guncellemesi eklenebilir.
- Icerik akisi: `GPT taslak -> manuel/editoryal kontrol -> onayli veri -> uygulama`.
