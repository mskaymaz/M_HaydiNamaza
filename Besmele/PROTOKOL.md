# BESMELE PROTOKOL

Amac: baglami en dusuk tokenle ve en hizli sirayla almak; bunu yaparken uretim seviyesi kalite, mimari disiplin ve profesyonel teslim davranisini korumak.

Kanonik cekirdek:
- `Besmele/PROTOKOL.md`
- `Besmele/STATE.md`
- `Besmele/WORKBOARD.md`
- `Besmele/plans/TASK-xxx.md`
- `Besmele/QUALITY_GATE.md`
- `Besmele/PUSH_LOG.md`
- `Besmele/ADR.md`

Opsiyonel referanslar:
- `Besmele/TOKEN_RULES.md`
- `Besmele/CONVENTIONS.md`
- `Besmele/ARCH_BASE.md`
- `Besmele/UI_SYSTEM.md`
- `Besmele/DECISIONS.md`
- `Besmele/UI_NOTES.md`
- `Proje/*.md`

Ilke:
- Ekonomik token, daha az kalite degil; daha az tarama, daha az tekrar ve daha temiz kanonik hafiza demektir.
- Sohbet gecici, markdown kayitlari kalicidir.
- Ortak ilke cekirdekte tutulur; uygulama-ozel detay yalniz gerektiginde acilir.

Kilit hatirlatici:
- Her yeni kullanici talimati gorulur gorumaz, daha cevap yazmadan once bu bolum otomatik yeniden hatirlanmis kabul edilir.
- Bu hatirlama sessiz uygulanir; kullanici ozellikle istemedikce her seferinde uzun aciklama olarak tekrar yazilmaz.
- Ekonomik token preflight zorunludur: her cevap, plan, arac, duzeltme, snapshot, commit ve push oncesi sessizce su cumle birebir yeniden hatirlanip uygulanir: `Execute only the explicitly requested scope; do not scan unrelated files, do not broaden the search/changes, and keep responses minimal (one-line status unless asked).`
- Her anlamli yanit ve her arac kullanimindan hemen once su 4 kontrol zorunludur:
  1. Yalniz istenen kapsami mi yapiyorum?
  2. Gerekenden fazla dosya veya tekrar aciklama uretiyor muyum?
  3. Ayni bilgiyi ikinci kez mi anlatiyorum?
  4. Bu mesaji daha kisa ama ayni derecede net yazabilir miyim?
- Bu 4 kontrolden biri `evet, sapma var` sonucuna giderse once ciktiyi kisalt, tekrari sil ve sonra devam et.
- Kullanici token ekonomisini hatirlattiysa ayni oturumun kalaninda bu bolum `sert mod` kabul edilir.
- Kullanici token ekonomisini `her talimatta hatirla` seviyesine cikardiysa bu durum yeni bir hatirlatma gelene kadar kalici varsayim sayilir.

Bootstrap:
1. `Besmele/PROTOKOL.md` ve `Besmele/STATE.md` oku.
2. Yalniz gerekiyorsa `Besmele/WORKBOARD.md` oku.
   - gorev listesi sorulduysa
   - `STATE.active_task` bos/uyumsuzsa
3. Kod degisikligi oncesi yalniz ilgili `Besmele/plans/TASK-xxx.md` dosyasini oku.
4. Gorev mimari/UI/urun karari gerektiriyorsa yalniz ilgili referans dosyasini ac:
   - mimari icin `ARCH_BASE.md`
   - UI sistemi icin `UI_SYSTEM.md`
   - tarihsel karar icin `DECISIONS.md` veya `ADR.md`
   - proje-ozel detay icin `Proje/*.md`
5. Gerekmedikce ek dokuman acma.

Kayit:
- `STATE.md`: tek ekranlik snapshot.
- `TASK-xxx.md`: kronolojik mikro-log yerine toplu durum ozeti.
- `WORKBOARD.md`: kisa tablo.
- `PUSH_LOG.md`: teslim/handover etiketi.
- Snapshot tetigi:
  - kullanici `snapshot al` derse hemen yaz
  - arada snapshot yoksa 8 anlamli tamamlanmis kullanici talimatinda otomatik yaz
  - gorev degisimi, oturum kapatisi, commit/push veya `usb ye yedekle` oncesi zorunlu yaz
- Her snapshot sonra sayaci sifirla.

Teslim:
- Commit/push akisi da ayni preflight'a tabidir; kayit disinda kapsam genisletilmez ve ilgisiz dosya stage edilmez.
- Commit/push/USB yedek oncesi `STATE`, `WORKBOARD`, ilgili `TASK` ve gerekirse `ADR` guncellenir.
- Sonra `QUALITY_GATE` ve teslim adimi uygulanir.
