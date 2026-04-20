from argparse import ArgumentParser
from datetime import datetime
from pathlib import Path
from shutil import copy2, rmtree
import subprocess
import sys

arac_dizini = Path(__file__).resolve().parent
if str(arac_dizini) not in sys.path:
    sys.path.insert(0, str(arac_dizini))
from r_etiketi_uret import r_etiketi_uret


def zaman_muhru_uret(an=None):
    zaman = an or datetime.now().astimezone()
    bolge = zaman.strftime("%z")
    bolge_kolonlu = f"{bolge[:3]}:{bolge[3:]}" if bolge else "+00:00"
    return f"{zaman.strftime('%Y-%m-%d %H:%M')} {bolge_kolonlu}"


def komut_calistir(argumanlar, repo_kok):
    return subprocess.run(
        argumanlar,
        cwd=repo_kok,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )


def state_degeri_oku(repo_kok, anahtar, varsayilan="NONE"):
    state_yolu = repo_kok / "STATE.md"
    if not state_yolu.exists():
        return varsayilan
    for satir in state_yolu.read_text(encoding="utf-8").splitlines():
        if satir.startswith(f"{anahtar}:"):
            return satir.split(":", 1)[1].strip() or varsayilan
    return varsayilan


def aktif_oturum_metni(ref, etiket, repo_adi, dal, ozet, sonraki_adim, durum_ciktisi):
    satirlar = [satir for satir in durum_ciktisi.splitlines() if satir.strip()]
    degisenler = []
    untracked = []

    for satir in satirlar:
        yol = satir[3:].strip()
        if not yol:
            continue
        degisenler.append(yol)
        if satir.startswith("?? "):
            untracked.append(yol)

    degisen_metin = "\n".join(f"- {yol}" for yol in degisenler) if degisenler else "- Yok."
    untracked_metin = "\n".join(f"- {yol}" for yol in untracked) if untracked else "- Yok."
    sonraki = sonraki_adim.strip() or "Bu oturumu devralirken `AKTIF_OTURUM.patch` gerekip gerekmedigini kontrol et."

    return (
        "# AKTIF OTURUM\n\n"
        "durum: AKTIF\n"
        f"etiket: {etiket}\n"
        f"updated: {zaman_muhru_uret()}\n"
        f"ref: {ref}\n"
        f"repo: {repo_adi}\n"
        f"branch: {dal}\n\n"
        "ozet:\n"
        f"- {ozet.strip() or 'Kisa oturum ozeti verilmedi.'}\n\n"
        "degisen_dosyalar:\n"
        f"{degisen_metin}\n\n"
        "untracked_kopyalari:\n"
        f"{untracked_metin}\n\n"
        "sonraki_adim:\n"
        f"- {sonraki}\n\n"
        "not:\n"
        "- Yeni oturumda bu dosya ve gerekirse `AKTIF_OTURUM.patch` okunur.\n"
    )


def aktif_oturum_temizle(repo_kok):
    oturum_kok = repo_kok / "Besmele" / "oturumlar"
    oturum_kok.mkdir(parents=True, exist_ok=True)
    (oturum_kok / "AKTIF_OTURUM.md").write_text(
        (
            "# AKTIF OTURUM\n\n"
            "durum: BOS\n"
            "etiket: NONE\n"
            "updated: NONE\n"
            "ref: NONE\n"
            "repo: NONE\n"
            "branch: NONE\n\n"
            "ozet:\n"
            "- Acik yari kalan oturum yok.\n\n"
            "degisen_dosyalar:\n"
            "- Yok.\n\n"
            "sonraki_adim:\n"
            "- Yeni bir teslim oncesi veya yari kalan iste `oturum_arsivle.py` bu dosyayi gunceller.\n\n"
            "not:\n"
            "- Bu dosya yeni oturumda `STATE`, aktif `TASK` ve `HISTORY` sonrasinda okunur.\n"
        ),
        encoding="utf-8",
    )
    patch_yolu = oturum_kok / "AKTIF_OTURUM.patch"
    if patch_yolu.exists():
        patch_yolu.unlink()
    untracked_kok = oturum_kok / "untracked"
    if untracked_kok.exists():
        rmtree(untracked_kok)


def oturum_arsivi_yaz(repo_kok, ozet, sonraki_adim="", ref=""):
    etiket = r_etiketi_uret()
    repo_adi = repo_kok.name
    dal = komut_calistir(["git", "branch", "--show-current"], repo_kok).stdout.strip() or "NONE"
    ref_degeri = ref.strip() or state_degeri_oku(repo_kok, "active_task", "NONE")
    durum = komut_calistir(["git", "status", "--short"], repo_kok).stdout
    patch = komut_calistir(["git", "diff", "--binary", "HEAD"], repo_kok).stdout

    oturum_kok = repo_kok / "Besmele" / "oturumlar"
    oturum_kok.mkdir(parents=True, exist_ok=True)

    (oturum_kok / "AKTIF_OTURUM.md").write_text(
        aktif_oturum_metni(
            ref=ref_degeri,
            etiket=etiket,
            repo_adi=repo_adi,
            dal=dal,
            ozet=ozet,
            sonraki_adim=sonraki_adim,
            durum_ciktisi=durum,
        ),
        encoding="utf-8",
    )

    if patch.strip():
        (oturum_kok / "AKTIF_OTURUM.patch").write_text(patch, encoding="utf-8")
    else:
        patch_yolu = oturum_kok / "AKTIF_OTURUM.patch"
        if patch_yolu.exists():
            patch_yolu.unlink()

    untracked_kok = oturum_kok / "untracked"
    if untracked_kok.exists():
        rmtree(untracked_kok)
    untracked_kok.mkdir(parents=True, exist_ok=True)

    for satir in durum.splitlines():
        if not satir.startswith("?? "):
            continue
        goreli = satir[3:].strip()
        if not goreli or goreli.startswith("Besmele/oturumlar/"):
            continue
        kaynak = repo_kok / goreli
        if not kaynak.exists() or not kaynak.is_file():
            continue
        hedef = untracked_kok / goreli
        hedef.parent.mkdir(parents=True, exist_ok=True)
        copy2(kaynak, hedef)

    return etiket


def ana():
    arguman = ArgumentParser(description="Aktif oturum ozeti ve git diff patch kaydi uretir.")
    arguman.add_argument("--kip", choices=["arsivle", "temizle"], default="arsivle")
    arguman.add_argument("--ozet", default="", help="Kisa oturum ozeti.")
    arguman.add_argument("--sonraki-adim", default="", help="Bir sonraki ilk adim.")
    arguman.add_argument("--ref", default="", help="TASK veya benzeri referans.")
    arguman.add_argument("--repo", default=".", help="Repo kok yolu.")
    secim = arguman.parse_args()

    repo_kok = Path(secim.repo).resolve()
    if secim.kip == "temizle":
        aktif_oturum_temizle(repo_kok)
        print("TEMIZ: Besmele/oturumlar aktif kaydi sifirlandi")
        return

    etiket = oturum_arsivi_yaz(
        repo_kok=repo_kok,
        ozet=secim.ozet,
        sonraki_adim=secim.sonraki_adim,
        ref=secim.ref,
    )
    print(f"ARSIV: {etiket} | Besmele/oturumlar/AKTIF_OTURUM.md")


if __name__ == "__main__":
    ana()
