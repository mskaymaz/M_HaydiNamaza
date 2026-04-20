# BESMELE

Amac: M_HaydiNamaza icinde ekonomik token odakli, kokte hafif ama proje hafizasini koruyan calisma omurgasi saglamak.

Uygulama ozeti:
- Flutter tabanli mobil namaz vakitleri uygulamasi.
- Temel kapsam: prayer engine, konum/favoriler, hatirlatmalar, kibla, i18n, ayarlar ve dini icerik veri setleri.

Kanonik giris:
- KOK tetikleyiciler: `AGENTS.md`, `CORE.md`, `STATE.md`
- Operasyon klasoru: `Besmele/`

Korunan proje hafizasi:
- `Besmele/WORKBOARD.md`, `Besmele/STATE.md`, `Besmele/plans/`
- `Besmele/UI_SYSTEM.md`, `Besmele/UI_NOTES.md`, `Besmele/DECISIONS.md`, `Besmele/ARCH_BASE.md`
- `Proje/` ve `ProjeOrj/` altindaki urun ve arastirma notlari
- `BesmeleGenel/` ve `ContextKit/` altindaki eski katmanlar legacy referans olarak korunur

Resmi Besmele dosyalari:
- `KURAL_KAYNAGI.md`
- `HEDEF_MIMARI.md`
- `KOMUT_SOZLUGU.md`
- `TEMIZLIK_POLITIKASI.md`
- `OPTIMIZE_POLITIKASI.md`
- `PROFIL_REHBERI.md`
- `ENTEGRASYON_REHBERI.md`
- `ENTEGRASYON_HARITASI.md`
- `WORKBOARD.md`
- `HISTORY.md`
- `FAZ_YOL_HARITASI.md`

Operasyon akisi:
1. Kokte `AGENTS/CORE/STATE` ile hizli giris yap.
2. Ardindan `Besmele/KOMUT_SOZLUGU.md` ile aktif tetikleri baglama al.
3. Proje hafizasini okumak gerektiginde once `Besmele/ENTEGRASYON_HARITASI.md`, sonra `WORKBOARD`, aktif `TASK`, gerekli ise legacy kaynaklar acilir.
4. `eko` ve `ozet`, cevap asamasinda yuzeyi en fazla 2-3 satira indirir.

R etiketi:
- Format: `R.yymmdd_hhmm`
- Kullanim: commit/push notu, `HISTORY` tag, bundle ve exe/paket adlari

Temel araclar:
- Dogrulama: `python Besmele/tools/validate_besmele.py`
- Derle araci: `python Besmele/tools/derle.py --ad MHaydiNamaza`

Yerel not:
- Bu repo daha once kendi Besmele, BesmeleGenel ve ContextKit katmanlarini tasiyordu.
- Yeni kok cekirdegi bunlari silmez; kanonik girisi sadelestirir ve mevcut hafizayi tek ust akista toplar.
