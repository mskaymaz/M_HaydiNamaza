# TASK-035

status: done
updated: 2026-03-24 15:04 +03:00
scope: `ayetler.json` icindeki tekrar eden ayetleri cikar, kalan benzersiz ayetleri yeniden numaralandir ve yeni uretimlerde haric tutulacak sure/ayet listesini cikar.

done_summary:
- Mevcut veri setinde ayni sure/ayet kaynaginin cok sayida tekrar ettigi goruldu.
- Tekrar eden sure/ayet kayitlari ayiklandi.
- Kalan benzersiz ayetler `ayet_001..ayet_072` olarak yeniden numaralandirildi.
- Haric tutulacak mevcut sure/ayet envanteri `ayetler_mevcut_sure_ayet.txt` dosyasina yazildi.

now:
- Teknik ve icerik tekillestirme tamamlandi.

next:
- Kalan kayit sayisini netlestir.
- Eksik kalan adet icin kullanilacak haric listeli prompt zeminini hazirla.

refs:
- `ayetler.json`
