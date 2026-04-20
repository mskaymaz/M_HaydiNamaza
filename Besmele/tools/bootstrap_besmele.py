from argparse import ArgumentParser
from datetime import datetime
from pathlib import Path
from shutil import copy2


KOK_SABLON_DOSYALARI = ["AGENTS.md", "CORE.md"]

BESMELE_SABLON_DOSYALARI = [
    "README.md",
    "KURAL_KAYNAGI.md",
    "HEDEF_MIMARI.md",
    "KOMUT_SOZLUGU.md",
    "TEMIZLIK_POLITIKASI.md",
    "OPTIMIZE_POLITIKASI.md",
    "PROFIL_REHBERI.md",
    "ENTEGRASYON_REHBERI.md",
    "FAZ_YOL_HARITASI.md",
]

BESMELE_ALT_DIZIN_DOSYALARI = {
    "hooks": ["pre-commit", "pre-commit.cmd"],
    "optional": ["CIHAZ_TESTI.md"],
    "oturumlar": ["AKTIF_OTURUM.md", "README.md"],
    "plans": ["TASK-SABLON.md"],
    "tools": [
        "validate_besmele.py",
        "ci_dogrula.sh",
        "ci_dogrula.cmd",
        "ci_github_actions_ornek.yml",
        "r_etiketi_uret.py",
        "history_ekle.py",
        "oturum_arsivle.py",
        "teslim_noktasi.py",
        "derle.py",
        "bootstrap_besmele.py",
    ],
}


def zaman_muhru_uret(an=None):
    """zaman_muhru: STATE/WORKBOARD/HISTORY acilis kaydinda kullanilan damga."""
    zaman = an or datetime.now().astimezone()
    bolge = zaman.strftime("%z")
    bolge_kolonlu = f"{bolge[:3]}:{bolge[3:]}" if bolge else "+00:00"
    return f"{zaman.strftime('%Y-%m-%d %H:%M')} {bolge_kolonlu}"


def state_sablonu():
    anlik = zaman_muhru_uret()
    return (
        "# BESMELE STATE\n\n"
        f"last_update: {anlik}\n"
        "active_task: NONE\n"
        "phase: Bootstrap tamamlandi; ilk gorev tanimi bekleniyor.\n"
        "next_step: Ilk TASK kaydini ac, WORKBOARD satiri ekle ve scope netlestir.\n"
        "blockers: NONE\n"
        "active_owner: UNASSIGNED\n"
        "last_delivery: NONE\n"
        "handover: Yeni repo omurgasi kuruldu; proje hedefi netlesince plan gorevine gec.\n"
    )


def workboard_sablonu():
    return (
        "# BESMELE WORKBOARD\n\n"
        "Allowed status: planned | in_progress | blocked | review | done\n\n"
        "| Task ID | Status | Owner | Updated | Summary |\n"
        "| --- | --- | --- | --- | --- |\n\n"
        "Ne zaman acilir?\n"
        "- Gorev listesi, durum ozetleri ve sahiplik kontrolu gerektiginde.\n"
    )


def history_sablonu():
    return (
        "# BESMELE HISTORY\n\n"
        "Amac: Teslim, handover, snapshot ve kararlar icin tek append-only gecmis tutmak.\n\n"
        "| Date | Tag | Type | Ref | Summary |\n"
        "| --- | --- | --- | --- | --- |\n\n"
        "Ne zaman acilir?\n"
        "- Anlamli teslim, karar, snapshot veya handover kaydi ekleneceginde.\n"
    )


def kopyala_veya_atla(kaynak, hedef, zorla):
    """kopya_durumu: dosyanin yeni yazildigini veya atlandigini bildirir."""
    hedef.parent.mkdir(parents=True, exist_ok=True)
    if hedef.exists() and not zorla:
        return "atla"
    copy2(kaynak, hedef)
    return "yaz"


def metin_yaz_veya_atla(hedef, icerik, zorla):
    hedef.parent.mkdir(parents=True, exist_ok=True)
    if hedef.exists() and not zorla:
        return "atla"
    hedef.write_text(icerik, encoding="utf-8")
    return "yaz"


def ana():
    arguman = ArgumentParser(description="Besmele omurgasini yeni bir repoya tek komutla kurar.")
    arguman.add_argument(
        "hedef",
        nargs="?",
        default=".",
        help="Kurulum yapilacak repo kok yolu.",
    )
    arguman.add_argument(
        "--zorla",
        action="store_true",
        help="Var olan dosyalari ezerek kur.",
    )
    secim = arguman.parse_args()

    kaynak_kok = Path(__file__).resolve().parents[2]
    kaynak_besmele = Path(__file__).resolve().parents[1]
    hedef_kok = Path(secim.hedef).resolve()
    hedef_besmele = hedef_kok / "Besmele"
    hedef_besmele.mkdir(parents=True, exist_ok=True)

    yazilan_sayisi = 0
    atlanan_sayisi = 0

    for dosya_adi in KOK_SABLON_DOSYALARI:
        kaynak = kaynak_kok / dosya_adi
        hedef = hedef_kok / dosya_adi
        sonuc = kopyala_veya_atla(kaynak, hedef, secim.zorla)
        yazilan_sayisi += 1 if sonuc == "yaz" else 0
        atlanan_sayisi += 1 if sonuc == "atla" else 0

    for dosya_adi in BESMELE_SABLON_DOSYALARI:
        kaynak = kaynak_besmele / dosya_adi
        hedef = hedef_besmele / dosya_adi
        sonuc = kopyala_veya_atla(kaynak, hedef, secim.zorla)
        yazilan_sayisi += 1 if sonuc == "yaz" else 0
        atlanan_sayisi += 1 if sonuc == "atla" else 0

    for alt_dizin, dosyalar in BESMELE_ALT_DIZIN_DOSYALARI.items():
        for dosya_adi in dosyalar:
            kaynak = kaynak_besmele / alt_dizin / dosya_adi
            hedef = hedef_besmele / alt_dizin / dosya_adi
            sonuc = kopyala_veya_atla(kaynak, hedef, secim.zorla)
            yazilan_sayisi += 1 if sonuc == "yaz" else 0
            atlanan_sayisi += 1 if sonuc == "atla" else 0

    sonuc = metin_yaz_veya_atla(hedef_kok / "STATE.md", state_sablonu(), secim.zorla)
    yazilan_sayisi += 1 if sonuc == "yaz" else 0
    atlanan_sayisi += 1 if sonuc == "atla" else 0

    sonuc = metin_yaz_veya_atla(hedef_besmele / "WORKBOARD.md", workboard_sablonu(), secim.zorla)
    yazilan_sayisi += 1 if sonuc == "yaz" else 0
    atlanan_sayisi += 1 if sonuc == "atla" else 0

    sonuc = metin_yaz_veya_atla(hedef_besmele / "HISTORY.md", history_sablonu(), secim.zorla)
    yazilan_sayisi += 1 if sonuc == "yaz" else 0
    atlanan_sayisi += 1 if sonuc == "atla" else 0

    print(f"KURULUM TAMAM: hedef={hedef_kok}")
    print(f"YAZILAN: {yazilan_sayisi}")
    print(f"ATLANAN: {atlanan_sayisi}")


if __name__ == "__main__":
    ana()
