# TASK-029

status: planned
updated: 2026-03-24 14:04 +03:00
scope: Gorme zorlugu yasayan kullanicilar icin tum arayuzu birlikte buyutebilen ve tasan alani kaydirarak gezmeyi saglayan erisilebilir buyutme modu tasarla.

goal:
- Yazi, ikon, sekil, resim ve panel olcekleri birlikte buyusun.
- Ekrana sigmayan durumda kullanici saga-sola ve yukari-asagi kaydirarak arayuzu gezebilsin.
- Buyutme/kucultme kontrolu gerektiginde gorunsun, is bitince gizlenebilsin.
- Bu ozellik ayarlardan acilabilen bir mod veya yardimci kontrol olarak yonetilsin.

notes_for_us:
- Tek tek widget buyutmek yerine merkezi olcek mantigi tercih edilmeli.
- Kaydirma davranisi hem dikey hem yatay yone izin vermeli.
- Normal kullanim bozulmamali; ozellik kapaliyken mevcut UI aynen kalmali.
- Kullaniciya karmasik gelmeyecek sade bir kontrol yapisi secilmeli.

acceptance_hint:
- Kullanici arayuzu buyutebiliyor.
- Buyuyen yapi kirpilmadan gezilebiliyor.
- Kontrol yapisi kalici karmasa olusturmuyor; istege bagli aciliyor/gizleniyor.

next:
- Uygun mimariyi sec: global UI scale + kaydirilabilir kapsayici + gecici kontrol cubugu.
