# OTURUMLAR

Amac: Yari kalan veya devredilecek islerde kisa oturum ozeti ile teknik `git diff` patch kaydini ayni yerde tutmak.

## Dosyalar
- `AKTIF_OTURUM.md`: Su an devralinacak en guncel oturum ozeti.
- `AKTIF_OTURUM.patch`: `git diff` tabanli teknik fark kaydi; gerekiyorsa okunur.
- `untracked/`: Commitlenmemis yeni dosyalarin kopyalari; yalniz aktif oturum varsa doldurulur.

## Okuma Sirasi
1. `STATE.md`
2. Aktif `TASK`
3. Son `HISTORY`
4. `AKTIF_OTURUM.md`
5. Gerekirse `AKTIF_OTURUM.patch`

Ne zaman acilir?
- Uzun calisma yari kaldiginda, baska kisi devralacaginda veya `yedek/mola` akisi oturum emniyet kaydi ureteceginde.
