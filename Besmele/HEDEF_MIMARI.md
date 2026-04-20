# HEDEF MIMARI

Amac: Besmele'yi tum repolara tasinabilen, hafif, AI-dostu, profesyonel urun dusunmesini varsayilan yapan sade ama ileri seviye bir repo-ustu cekirdege donusturmek.

## Nihai Yon
- Kokte yalniz tetikleyiciler kalir: `AGENTS.md`, `CORE.md`, `STATE.md`.
- `Besmele/` altinda tek kaynakli, kisa ve tekrar etmeyen operasyon omurgasi bulunur.
- AI varsayilan olarak derinlikli ve durust tavsiye verir; kullanici acikca daraltmadikca yalniz komut uygulamakla sinirli kalmaz.
- Ayni cekirdek, farkli repo turlerinde `profil` mantigiyla uyarlanir.

## Tasarim Ilkeleri
- `tek_kaynak`: Bir kural tek resmi kaynaktan okunur; diger dosyalar kisa referans verir.
- `ekonomik_token`: Yalniz gereken kapsama inilir; cikti kisa ama karar guclu tutulur.
- `derinlikli_tavsiye`: AI mimari, kalite, risk, ergonomi, performans ve sadelik konusunda varsayilan olarak dusunur.
- `rol_bazli_degerlendirme`: Coklu AI kullanimi model ismiyle degil, rol dagilimi ile ele alinir.
- `profil_bazli_uyarlama`: Ayni omurga `mini`, `standart`, `ileri` gibi seviyelere uyarlanabilir.
- `teknoloji_bagimsiz_cekirdek`: Besmele belirli bir dil veya catinin degil, repo-ustu calisma sisteminin adidir.
- `hafiza_koruma`: Mevcut repo task ve ilerleme hafizasi otomatik silinmez; once anlasilir, sonra haritalanir.

## Calisma Modlari
- `ozetten_kur`: Yeni repo icin proje ozetini, hedef platformlari ve profil seviyesini alip Besmele omurgasi ile ilk mimariyi kurar.
- `repoyu_incele`: Mevcut repo yapisini, kodlarini, talimat dosyalarini ve ilerleme hafizasini okuyup baglama alir.
- `temizlik_oner`: Gereksiz, cakisan veya artik aktif olmayan dosyalari aday liste halinde sunar; silme karari kullanici onayi ile verilir.

## Entegrasyon Ciktisi
- `ENTEGRASYON_HARITASI`: Mevcut repo icin uretilen ozet ciktidir.
- Icerik: baglam ozeti, korunan task hafizasi, Besmele ile eslesecek dosyalar, temizlik adaylari, kullanici onayi gereken maddeler.
- Amaç: Eski yapinin ustunu cizmek degil, mevcut repo hafizasini guvenli sekilde Besmele'ye baglamaktir.

## Hedef Dosya Agaci
```text
repo/
├─ AGENTS.md
├─ CORE.md
├─ STATE.md
└─ Besmele/
   ├─ README.md
   ├─ KURAL_KAYNAGI.md
   ├─ HEDEF_MIMARI.md
   ├─ KOMUT_SOZLUGU.md
   ├─ TEMIZLIK_POLITIKASI.md
   ├─ OPTIMIZE_POLITIKASI.md
   ├─ PROFIL_REHBERI.md
   ├─ ENTEGRASYON_REHBERI.md
   ├─ WORKBOARD.md
   ├─ HISTORY.md
   ├─ FAZ_YOL_HARITASI.md
   ├─ oturumlar/
   ├─ plans/
   ├─ tools/
   ├─ hooks/
   └─ optional/
```

## Katmanlar
- `cekirdek`: Asistanin ilk okuma ve davranis omurgasi. Kokte kalir.
- `operasyon`: Kurallar, komut sozlugu, entegrasyon ve hafiza dosyalari. `Besmele/` kokunde kalir.
- `yardimci`: Script, hook ve dogrulama araclari. `tools/` ve `hooks/` altinda kalir.
- `opsiyonel`: Her repoda zorunlu olmayan yardimcilar. Ornek: cihaz testi, yerel reset araclari, teknolojiye ozel notlar.
- `oturumlar`: Yari kalan islerde devri kolaylastiran aktif oturum ozeti ve patch kayitlari.
- `arsiv`: Eski karar veya artik aktif olmayan varliklar. Gerektiginde ayri klasorde tutulur.

## Hedef Belgeler
- `KOMUT_SOZLUGU`: Sohbet tetiklerini tek listede toplayan referans dosya; `list?` bu dosyanin ozet gorunumudur.
- `TEMIZLIK_POLITIKASI`: Guvenli artefakt temizliginin sinirlarini ve aday desenlerini tanimlar.
- `OPTIMIZE_POLITIKASI`: Mimari kaliteyi dusurmeyen guvenli konsolidasyon sinirlarini tanimlar.
- `PROFIL_REHBERI`: `mini`, `standart`, `ileri` gibi uygulama olgunluk seviyelerini tanimlayan rehber.
- `ENTEGRASYON_REHBERI`: Besmele'nin yeni veya mevcut repoya nasil kurulacagini anlatan teknik akistir.
- `ENTEGRASYON_HARITASI`: Mevcut repo entegrasyonunda uretilen, task hafizasini ve temizlik kararlarini baglayan cikti modelidir.
- `oturumlar/`: Yari kalan calismalar icin `OTURUM_OZETI + git diff patch` yapisini tasir.

## Gecis Karari
1. Once mimari sadeleştirilir ve dosyalar yeniden haritalanir.
2. Sonra komut yuzeyi ve profil belgeleri acilir.
3. En son bootstrap, validator ve diger araclar yeni agaca senkronlanir.

Ne zaman acilir?
- Besmele'nin hedef mimarisi, dosya sadeleştirmesi veya diger repolara entegrasyon karari gerektiginde.
