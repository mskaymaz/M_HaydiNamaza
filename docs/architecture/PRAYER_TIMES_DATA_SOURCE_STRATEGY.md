# PRAYER_TIMES_DATA_SOURCE_STRATEGY

## 1. Amaç ve kapsam
Bu dokümanın amacı, M_HaydiNamaza uygulamasında namaz vakti verisinin hangi kaynaklardan, hangi kurallarla ve hangi şeffaflık düzeyiyle kullanılacağını net bir çerçeveye oturtmaktır.

Kapsam:
- Veri kaynağı seçeneklerini karşılaştırmak
- Geçici ve kalıcı mimariyi ayırmak
- Kullanıcıya gösterilecek kaynak kalitesi yaklaşımını tanımlamak
- Release öncesi zorunlu karar ve test kapılarını belirlemek

Kapsam dışı:
- Bu aşamada kod akışı/fallback sırası değiştirmek
- Resmi yanıt gelmeden kesin kaynak kararı vermek

## 2. Mevcut durum
- 2026-05-12 itibarıyla CİMER/Diyanet cevabı bekleniyor.
- Resmi/izinli veri stratejisi netleşmeden release yapılmayacak.
- TASK-04A tamamlandı; mevcut servis yapısı orkestrasyon/fallback kararını taşıyor.
- Mevcut durumda gizli/fragil endpoint kullanımının kalıcı mimari olmaması temel prensip.

## 3. Zorunlu karar kriterleri
Veri stratejisi aşağıdaki kriterler birlikte sağlanacak şekilde seçilmelidir:

- Hukuki izin: Kaynağın kullanım hakkı, lisans ve dağıtım izni açık olmalı.
- Veri doğruluğu: İl/ilçe bazında güvenilir ve doğrulanabilir sonuç üretmeli.
- Sürdürülebilirlik: Kaynak erişimi uzun vadede kesintisiz ve bakım yapılabilir olmalı.
- Offline uygunluk: Ağ yokken kullanıcıyı tamamen işlevsiz bırakmamalı.
- Maliyet: API, depolama, güncelleme ve bakım maliyetleri yönetilebilir olmalı.
- Kullanıcıya şeffaflık: Veri kaynağı ve kalite düzeyi kullanıcıya açıkça gösterilmeli.

## 4. Aday veri kaynakları karşılaştırması
Kesin karar için resmi yanıt beklendiğinden, aşağıdaki seçenekler ön değerlendirme seviyesindedir.

### 4.1 Resmi Diyanet API veya lisanslı veri
Artılar:
- Kurumsal güven ve dini içerik tutarlılığı açısından güçlü aday.
- Ürün güvenilirliği anlatısında en net seçenek.

Riskler/Sorular:
- API erişim modeli, kota ve lisans şartları net değil.
- Ticari/halka açık uygulama kullanım koşulları teyit gerektiriyor.

### 4.2 Yıllık/aylık şehir-ilçe offline veri paketi
Artılar:
- Offline dayanıklılığı yüksek.
- Performans ve öngörülebilirlik iyi.

Riskler/Sorular:
- Paket güncelleme döngüsü ve dağıtım mekanizması netleşmeli.
- Veri güncelliği ve bakım operasyonu maliyetli olabilir.

### 4.3 İzinli/üretilmiş doğrulanmış cache
Artılar:
- Hızlı erişim ve ağ bağımlılığını azaltma avantajı.
- Resmi kaynaktan türetilirse kullanıcı deneyimi dengelenebilir.

Riskler/Sorular:
- Türetim ve yeniden dağıtım izni açık olmalı.
- Cache üretim doğrulama süreci resmi olarak tanımlanmalı.

### 4.4 Üçüncü taraf API fallback
Artılar:
- Erişilebilirlik ve yedeklilik sağlar.
- Geçiş döneminde operasyonel esneklik verebilir.

Riskler/Sorular:
- Metodoloji farkları nedeniyle resmi kaynakla sapma olabilir.
- Uzun vadede bağımlılık/maliyet riski oluşabilir.

### 4.5 Yaklaşık hesaplama fallback
Artılar:
- Tam veri yokken minimum hizmet sürekliliği sağlar.
- Ağsız senaryoda son çare yaklaşımı olabilir.

Riskler/Sorular:
- Kullanıcıda â€œresmi vakitâ€ algısı oluşturulmamalı.
- Bölgesel/doğruluk sapmaları net biçimde etiketlenmeli.

## 5. Geçici mimari ve kalıcı mimari ayrımı
Geçici mimari (CİMER/Diyanet yanıtı öncesi):
- Mevcut fallback orkestrasyonu korunur.
- Kaynak kalitesi etiketleme hazırlığı yapılır.
- Release kararı bloklu kalır.

Kalıcı mimari (resmi karar sonrası):
- Birincil kaynak resmi/izinli stratejiye bağlanır.
- Fallback sırası lisans ve doğruluk kurallarına göre kesinlenir.
- Veri güncelleme/dağıtım akışı resmi stratejiyle standartlaştırılır.

## 6. Source quality / veri kaynağı etiketi planı
Uygulama içinde kullanıcıya gösterilecek etiketler, kaynak güven düzeyini sade şekilde iletmelidir.

Olası source label değerleri ve kullanım çerçevesi:

| Label | Kullanıcıya kısa açıklama | Güven seviyesi | Release kabul durumu | Risk notu |
|---|---|---|---|---|
| `official_diyanet` | Resmi Diyanet kaynağından alınan veri. | Yüksek | Koşullu kabul (resmi izin/koşul teyidi sonrası) | Erişim ve lisans koşulları netleşmeden kalıcı karar verilmez. |
| `licensed_offline_diyanet` | Diyanet lisanslı offline veri paketinden sunulan veri. | Yüksek | Koşullu kabul (lisans + güncelleme modeli doğrulanınca) | Paket güncelliği ve dağıtım operasyonu düzenli yönetilmelidir. |
| `verified_cache` | İzinli kaynaktan üretilmiş ve doğrulanmış önbellek verisi. | Orta-Yüksek | Koşullu kabul (türetim/yeniden dağıtım izni açık ise) | Cache üretim hattı bozulursa eski veri riski doğar. |
| `third_party_api` | Doğrulanmış üçüncü taraf servisinden alınan veri. | Orta | Sınırlı kabul (fallback amacıyla) | Metodoloji farkı nedeniyle resmi kaynakla dakika sapması oluşabilir. |
| `calculated_fallback` | Yaklaşık hesaplama ile üretilen vakit verisi. | Düşük-Orta | Sadece acil fallback olarak kabul | Kullanıcı bunu resmi vakit sanmamalı; açık uyarı zorunludur. |
| `unknown` | Veri kaynağı doğrulanamadı veya etiket belirlenemedi. | Düşük | Release için kabul edilmez | Kaynak belirsizliği güven ve doğruluk riski üretir. |

Kesin karar notu:
- Resmi/Diyanet cevabı gelmeden source label isimleri final API contract olarak kabul edilmeyecek.
- Bu bölüm şu aşamada dokümantasyon taslağıdır.
- Etiket görünürlüğü kullanıcıdan saklanmamalıdır.

## 7. UI şeffaflık metni planı
Amaç, kullanıcıya "hangi veriyi neden görüyorum?" sorusunun net cevabını vermektir.

### 7.1 Ana ekranda kısa kaynak metinleri
Namaz vakti panelinde, vakit tablosuna yakın ve sade bir satırda gösterilir:
- `Kaynak: Resmi/izinli veri`
- `Kaynak: Doğrulanmış önbellek`
- `Kaynak: Üçüncü taraf doğrulanmış veri`
- `Kaynak: Yaklaşık hesaplama`
- `Kaynak: Belirsiz`

Ek kısa gösterim (opsiyonel):
- `Güven: Yüksek`
- `Güven: Orta`
- `Güven: Düşük`

### 7.2 Detay/yardım ekranı açıklama metinleri
Ayarlar veya yardım altında "Veri Kaynağı ve Güven Düzeyi" alanında gösterilir:
- `Bu uygulama, namaz vakitlerini seçili veri kaynağına göre sunar.`
- `Kaynak etiketi, verinin hangi tür kaynaktan geldiğini gösterir.`
- `Güven seviyesi, verinin doğrulanma düzeyini özetler.`
- `Mümkün olduğunda resmi/izinli kaynaklar önceliklendirilir.`

Label bazlı kısa açıklama örnekleri:
- `Resmi/izinli veri: Yetkili veya lisanslı kaynaktan alınır.`
- `Doğrulanmış önbellek: İzinli kaynaktan üretilmiş, sonradan doğrulanmış veridir.`
- `Üçüncü taraf veri: Resmi olmayan ancak teknik olarak doğrulanan kaynaktır.`
- `Yaklaşık hesaplama: Hesap yöntemine dayalı tahmini vakitlerdir.`

### 7.3 Yaklaşık hesaplama/fallback uyarı metinleri
`calculated_fallback` veya düşük güven durumunda görünür:
- `Bu vakitler yaklaşık olabilir.`
- `Konum ve yöntem farkı nedeniyle dakika düzeyinde sapma oluşabilir.`
- `Mümkünse resmi/izinli kaynak doğrulaması önerilir.`

`unknown` durumunda görünür:
- `Kaynak doğrulanamadı. Gösterilen vakitleri dikkatle değerlendirin.`

### 7.4 Resmi/izinli kaynak güven metinleri
`official_diyanet` veya `licensed_offline_diyanet` durumunda:
- `Vakitler resmi/izinli veri kaynağından sunulmaktadır.`
- `Kaynak güven seviyesi: Yüksek.`
- `Veri güncellemesi kaynak politikasına göre yapılır.`

### 7.5 Ton kuralları
- Korkutucu değil, açık ve dürüst bir dil kullanılır.
- Belirsizlik varsa saklanmaz; kısa ve sade şekilde belirtilir.
- Kullanıcıyı suçlayan veya panik oluşturan ifadeler kullanılmaz.
- Teknik detaylar yardım ekranında tutulur, ana ekranda kısa metin kullanılır.
- Kaynak kalitesi düşükse yönlendirici ama yumuşak uyarı verilir.

## 8. 10 şehir karşılaştırma test planı
Release öncesi en az 10 şehirde karşılaştırma yapılmalıdır.

Şehir/ilçe örnek listesi:
- İstanbul / Fatih
- Ankara / Çankaya
- İzmir / Konak
- Konya / Selçuklu
- Erzurum / Yakutiye
- Trabzon / Ortahisar
- Diyarbakır / Sur
- Antalya / Muratpaşa
- Van / İpekyolu
- Edirne / Merkez

Her şehir için karşılaştırılacak kaynaklar:
- Resmi/izinli Diyanet veri cevabı geldiyse resmi kaynak
- Mevcut Diyanet endpoint sonucu (geçici gözlem amaçlı)
- Aladhan sonucu
- Local calculated fallback sonucu

Kontroller:
- Aynı gün için her vakit kaleminde karşılaştırma:
  - imsak
  - güneş
  - öğle
  - ikindi
  - akşam
  - yatsı
- Kaynaklar arası dakika farkı raporu
- Kabul eşiğini aşan sapmalarda kök neden notu

Çıktı:
- Åehir bazlı fark tablosu
- Kaynak güven notu
- Release gate kararına girdi olacak özet değerlendirme

Kabul notu:
- Tolerans değerleri resmi kaynak stratejisi netleşmeden final kabul edilmeyecek.
- Büyük farklar release blocker kabul edilecek.
- Bu test planı şimdilik dokümantasyon taslağıdır.

## 9. Release gate / çıkış kriterleri
Production release öncesi aşağıdaki zorunlu şartlar birlikte sağlanmalıdır:

- CİMER/Diyanet cevabı değerlendirilmiş olmalı.
- Birincil veri kaynağı stratejisi netleşmiş olmalı.
- Source quality label planı uygulanabilir olmalı.
- 10 şehir karşılaştırma planı tamamlanmış olmalı.
- Kullanıcıya gösterilecek şeffaflık metinleri hazırlanmış olmalı.

Release blocker durumları:
- Resmi izin/lisans belirsizliği
- Gizli/fragil endpoint'e kalıcı bağımlılık
- Büyük vakit farkları
- Kaynak etiketi gösterilememesi
- Offline/fallback davranışının belirsiz kalması

Release kararı:
- Bu şartlar tamamlanmadan production release yapılmayacak.
- Gerekirse internal/test build yapılabilir; gerçek kullanıcı release'i yapılmayacak.

## 10. Açık kararlar ve beklenen cevaplar
Henüz kesinleşmeyen başlıklar:
- Diyanet tarafından sağlanacak resmi erişim modeli nedir?
- Lisans/yeniden dağıtım şartları nelerdir?
- Offline paket kullanımına resmi olarak hangi sınırlar uygulanır?
- Üçüncü taraf fallback hangi koşullarda devreye girebilir?
- Yaklaşık hesaplama hangi kullanıcı senaryosunda gösterilebilir?

Beklenen dış cevaplar:
- CİMER/Diyanet resmi yanıtı
- Gerekirse hukuki/lisans değerlendirme geri bildirimi

Bu cevaplar alınmadan kalıcı veri kaynağı kararı kesinleştirilmeyecektir.

