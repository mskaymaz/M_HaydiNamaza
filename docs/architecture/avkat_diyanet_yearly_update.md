# Avkat Diyanet Namaz Vakitleri Yıllık Güncelleme Rehberi

Bu belge, Diyanet namaz vakitleri verilerinin (`avkat` yapısı) yıllık güncelleme mekanizmasını ve çalışma ilkesini tanımlar.

---

## 1. Veri Kaynağı Yapısı (`avkat`)

- **Kamuya Açık Uzak Depo:** `https://github.com/mskaymaz/avkat`
- **Mevcut Sürüm Durumu:** Veriler **2026 sonuna kadar** eksiksiz ve geçerlidir.
- **Yerel Varlık Dizin Yapısı:** `assets/data/prayer/diyanet/{YIL}/index.json`

---

## 2. Yıllık Aralık Ayı Güncelleme Prosedürü

Her yılın **Aralık ayında** (örneğin Aralık 2026), bir sonraki takvim yılının (örneğin 2027) Diyanet resmi namaz vakitleri verileri şu adımlarla güncellenir:

1. **Uzak Depo Güncellemesi:**
   - Diyanet yeni yıl vakit verileri `https://github.com/mskaymaz/avkat` reposunda `{YIL}/index.json` olarak yayınlanır.

2. **Uygulama Yerel Varlıklarına (Assets) Eklenmesi:**
   - Yeni yıl `index.json` dosyası uygulamanın `assets/data/prayer/diyanet/{YIL}/index.json` klasörüne aktarılır.
   - `pubspec.yaml` altındaki asset tanımına gerekirse yeni yıl dizini eklenir (`- assets/data/prayer/diyanet/2027/`).

3. **Çalışma Zamanı (Runtime Fallback & Fetch):**
   - `DiyanetLocalPrayerTimesRepository` istemci sınıfı, talep edilen tarihin yılına göre `assets/data/prayer/diyanet/{YIL}/index.json` dosyasını otomatik okur.
   - Yerelde henüz bulunmayan gelecek yıl verileri için uzak raw URL (`https://raw.githubusercontent.com/mskaymaz/avkat/main/{YIL}/index.json`) üzerinden önbelleğe alarak kullanıcıya sunar.
