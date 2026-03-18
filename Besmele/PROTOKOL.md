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
- Commit/push/USB yedek oncesi `STATE`, `WORKBOARD`, ilgili `TASK` ve gerekirse `ADR` guncellenir.
- Sonra `QUALITY_GATE` ve teslim adimi uygulanir.
