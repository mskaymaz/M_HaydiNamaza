# TASKS_FLU.md - Flutter & Dart Mimari Dönüşüm ve Geliştirme Yol Haritası

Bu dosya, `flu` dalında gerçekleştirilecek temizlik, mimari dönüşüm, UI/UX düzeltmeleri ve Google Play yayınlama hazırlıklarının adım adım takip planıdır. Her görev tamamlandığında ilgili kutucuk `[x]` olarak işaretlenecektir.

---

## 📌 Aşama 1: Dal Yapılandırması ve Depo Temizliği (Clean Architecture & Legacy Cleanup)

- [x] **TASK 1.1:** Git `flu` dalının oluşturulması ve çalışma ortamının izole edilmesi.
- [x] **TASK 1.2:** C++ ve Python/PySide6 bağımlılığı olan eski araçların (`onay.py`, `incele.py`, `AllApp_push.py`, `tools/daily_content/allapp_push_tool.py` vb.) tespit edilmesi, güvenle kaldırılması veya arşivlenmesi.
- [x] **TASK 1.3:** Depodaki gereksiz ölü kodların (dead code), kullanılmayan test kalıntılarının ve eski dokümantasyon çöplerinin temizlenmesi.

---

## 📌 Aşama 2: Diyanet & Avkat Namaz Vakitleri ve Hijri Tarih Entegrasyonu

- [x] **TASK 2.1:** Diyanet verilerinin `https://github.com/mskaymaz/avkat` yapısından okunmasının doğrulanması ve üçüncü taraf Hicri tarih hesaplamalarının Diyanet/Avkat resmi Hicri takvim verisine bağlatılması.
- [x] **TASK 2.2:** Her yılın Aralık ayında bir sonraki yılın vakit verilerinin çekilip `avkat` yerel deposuna aktarılması için güncelleme mekanizmasının tanımlanması.

---

## 📌 Aşama 3: Sesli Okuma (TTS) & Ses Oynatıcı Durdurma / Pause Mantığı

- [x] **TASK 3.1:** Günün Ayeti/Hadisi panelindeki metin okuma butonunun Konuşma/Hoparlör (Speech) ikonuyla değiştirilmesi.
- [x] **TASK 3.2:** Günün içeriği ekranında okuma ikonuna tekrar basıldığında sesli okumanın anında durdurulması (Play/Stop toggle).
- [x] **TASK 3.3:** Ayarlar kısmındaki "Metin Okuma Testi" butonuna bas-başlat / bas-durdur (Pause/Stop) işlevselliğinin eklenmesi.
- [x] **TASK 3.4:** Kullanıcı tarafından indirilen ve dinlenen ezan seslerinde oynatma butonuna ikinci kez basıldığında sesi durdurma/duraklatma (Pause/Stop) mantığının eklenmesi.

---

## 📌 Aşama 4: Günün İçeriği Paneli Kaydırma Okları

- [x] **TASK 4.1:** Günün İçeriği panelindeki Ses ikonu (sağ) ve Bilgi ikonunun (sol) içeriye doğru kaydırılarak hizalanması.
- [x] **TASK 4.2:** En sağ ve en sol kenarlara sayfa geçişleri için Sağ (`>`) ve Sol (`<`) ok ikonlarının yerleştirilmesi.
- [x] **TASK 4.3:** Ok ikonlarına basıldığında sayfaların (Ayet, Hadis, Esma-i Hüsna, Sıfatlar) akıcı şekilde kaydırılmasının (page view / swiping) sağlanması.

---

## 📌 Aşama 5: Namazda Sessiz Kal ve Vakitler Paneli Yenilemesi

- [x] **TASK 5.1:** "Namaz Vaktinde Sessiz Kal" akışının (süre kontrolü, Android AlarmManager / NotificationPolicyEnforcer geri yükleme) test edilmesi ve hatalarının giderilmesi.
- [x] **TASK 5.2:** Vakit Ayarları penceresindeki ayrı olan Ses ve Titreşim seçeneklerinin tek bir birleşik Toggle altında birleştirilmesi.
- [x] **TASK 5.3:** Ezan okuma ayarlarındaki çift minareli cami ikonunun çağrışımı daha yüksek, modern bir Ezan/Çağrı ikonu ile değiştirilmesi.
- [x] **TASK 5.4:** Ana vakit kartlarındaki sessiz kal ikonunun görsel karmaşayı önlemek amacıyla Vakit Ayarları pop-up penceresine taşınması.

---

## 📌 Aşama 6: Hizalama Düzenlemeleri ve Kerahat Vakti Uyarısı

- [x] **TASK 6.1:** Ekran genelindeki hiza bozukluğu olan dikey/yatay `?` (Yardım) ikonlarının piksel bazlı hizalanması.
- [x] **TASK 6.2:** Üst sayaç kartına Kerahat Vakti girdiğinde kırmızılı yanıp sönen ve dile göre yerelleştirilmiş (TR/EN/AR) **"KERAHAT VAKTİDİR"** uyarısının eklenmesi.
- [x] **TASK 6.3:** Varsayılan kerahat vakti sürelerinin tanımlanması ve kullanıcıların Ayarlar sayfasından bu süreleri değiştirebilmesi için ayar modülünün yapılması.

---

## 📌 Aşama 7: İçerik İnceleme & Yönetim Aracının Flutter/Dart Mimarisine Taşınması

- [ ] **TASK 7.1:** Eski Python/PySide6 tabanlı Ayet/Hadis/Esma ekleme, inceleme ve onaylama aracının Flutter/Dart (Desktop/Web) mimarisinde kompakt ve modern bir araç olarak yeniden yazılması.
- [ ] **TASK 7.2:** Flutter içerik aracının onaylanan verileri `assets/data/daily_content/approved/` ve `AllApp` yayınlama yapısına eksiksiz aktarmasının sağlanması.

---

## 📌 Aşama 8: Google Play Hazırlıkları (`gp` Dalı & Store Release)

- [ ] **TASK 8.1:** Tüm `flu` dalı geliştirmeleri ve testleri tamamlandıktan sonra `gp` (Google Play) dalının açılması.
- [ ] **TASK 8.2:** Release derlemesi için `build.gradle.kts` ve `key.properties` üretim imza (`upload-keystore.jks`) yapılandırmasının yapılması.
- [ ] **TASK 8.3:** `gp` dalında güncelleme URL'lerinin Google Play Store sayfasına (`https://play.google.com/store/apps/details?id=com.mskaymaz.mhaydinamaza`) yönlendirilmesi.
- [ ] **TASK 8.4:** Android 14+ hassas izinlerin (`SCHEDULE_EXACT_ALARM`, `ACCESS_NOTIFICATION_POLICY`, `USE_FULL_SCREEN_INTENT`) Play Console beyanlarının hazırlanması ve `.aab` derlemesinin üretilmesi (`flutter build appbundle --release`).
- [ ] **TASK 8.5:** Tüm testler tamamlandıktan sonra Günün Ayeti/Hadisi başlığındaki test amaçlı konulmuş "Replace (Değiştir)" butonunun koddan tamamen kaldırılması.
