# TASK-033

status: done
updated: 2026-03-24 14:19 +03:00
scope: Bilgilendirme paneli icin icerik saklama ve dagitim kararini kalici kayda al.

decision_summary:
- Bilgilendirme paneli ayet, hadis ve fikhi mesele iceriklerini kapsar.
- Baslangic mimarisi `local-first` olacak.
- Icerikler uygulama ile birlikte yerel gelir; kullanici ilk kurulumda veriyi hazir bulur.
- Gunluk/random secim cihaz icinde yapilir.
- Gorsel, foto veya ses eki planlanmaz; icerik metin ve kaynak odakli kalir.
- Panel farki agirlikla renk ile ayristirilir.
- Veri hacmi buyuse bile ileride surumlu uzak icerik paketleriyle guncelleme eklenebilir.
- GPT icerik taslagi uretebilir; nihai veri editoryal kontrol sonrasi uygulamaya alinir.

notes_for_us:
- Ilk uygulama asamasinda seed JSON + yerel cache/db yaklasimi uygundur.
- Ilk surumde internet bagimliligi olmamasi tercih edilir.
- Gelecekte `manifest + pack` modeli eklenirse mevcut local-first akis bozulmadan gelistirilmelidir.

next:
- Icerikler hazir olunca ayet/hadis/fikhi mesele icin ortak veri semasi ve yerel depolama yapisi yazilacak.

refs:
- `AyetHadisFıkıh.md`
- `Besmele/ADR.md`
