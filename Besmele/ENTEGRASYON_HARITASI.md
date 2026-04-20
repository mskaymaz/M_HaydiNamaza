# ENTEGRASYON HARITASI

Amac: M_HaydiNamaza icindeki mevcut hafiza ve dokuman yapisini yeni Besmele cekirdegiyle nasil birlikte kullanacagimizi tek dosyada gostermek.

## baglam_ozeti
- Repo, Flutter tabanli mobil namaz vakitleri uygulamasi.
- Canli kod kapsami: prayer engine, konum/favoriler, uygulama ici hatirlatmalar, kibla, i18n, tema/palet ve ayarlar.
- Ana teknik odak artik yeni ozellik eklemekten cok mevcut yapinin platform seviyesi bildirim/ses, i18n, test ve sertlestirme adimlarina gecmesi.
- Planli aktif is `TASK-007` olarak korunuyor.

## hafiza_kaynaklari
- Kanonik ilk okuma: `AGENTS.md`, `CORE.md`, `STATE.md`
- Canli task hafizasi: `Besmele/WORKBOARD.md`, `Besmele/STATE.md`, `Besmele/plans/`
- Uygulama kararlari ve UI notlari: `Besmele/DECISIONS.md`, `Besmele/UI_SYSTEM.md`, `Besmele/UI_NOTES.md`, `Besmele/ARCH_BASE.md`
- Urun ve arastirma notlari: `Proje/`, `ProjeOrj/`, `HaydiNamazaTavsiyeler.md`
- Legacy hafiza: `BesmeleGenel/`, `ContextKit/`

## besmele_esleme
- Yeni kok cekirdegi ilk girisi sadelestirir; detayli baglam gerektiginde bu dosya uzerinden alt hafizaya inilir.
- `Besmele/WORKBOARD.md` mevcut is sirasinin ana listesi olmaya devam eder.
- `Besmele/plans/` mevcut gorev arsivi olarak korunur; yeni gorevler de ayni klasorde acilabilir.
- `BesmeleGenel/` ve `ContextKit/` referans niteliginde legacy katmanlardir; varsayilan acilis kaynagi degildir.
- `Proje/` ve `ProjeOrj/` urun yonu, test notu ve ilk mimari plan kaynagi olarak korunur.

## temizlik_adaylari
- `BesmeleGenel/` ve `ContextKit/` icindeki kopya protokol/state/workboard dosyalari ileride arsivlenebilir.
- `Besmele/WORKBOARD-1.md` aktif degilse arsiv adayi olabilir.
- Generic bootstrap dosyalari repo baglamina gore ileride daha da daraltilabilir.

## onay_bekleyenler
- Legacy klasorlerin (`BesmeleGenel/`, `ContextKit/`) arsivlenmesi veya silinmesi kullanici onayi olmadan yapilmayacak.
- `Besmele/WORKBOARD-1.md` ve diger olasi kopya hafiza dosyalari icin otomatik temizlik yapilmayacak.

## kanonik_akis
1. Yeni oturumda `STATE.md` okunur.
2. Gerekiyorsa bu `ENTEGRASYON_HARITASI.md` acilir.
3. Sonra `Besmele/WORKBOARD.md` ve ilgili `TASK` okunur.
4. Daha derin urun baglami gerekiyorsa `Proje/`, `ProjeOrj/` ve uygulama kodu okunur.
