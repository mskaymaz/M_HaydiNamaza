from argparse import ArgumentParser
from pathlib import Path
import subprocess
import sys

arac_dizini = Path(__file__).resolve().parent
if str(arac_dizini) not in sys.path:
    sys.path.insert(0, str(arac_dizini))
from history_ekle import satir_ekle, zaman_muhru_uret
from oturum_arsivle import aktif_oturum_temizle, oturum_arsivi_yaz, state_degeri_oku
from r_etiketi_uret import cikti_metni_uret, r_etiketi_uret


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


def state_guncelle(repo_kok, etiket, sonraki_adim):
    state_yolu = repo_kok / "STATE.md"
    satirlar = state_yolu.read_text(encoding="utf-8").splitlines()
    yeni = []
    handover = (
        "Teslim noktasi alindi; yeni oturumda `STATE`, aktif `TASK`, `HISTORY` "
        "ve gerekirse `Besmele/oturumlar/AKTIF_OTURUM.md` okunarak devam edilmeli."
    )
    degerler = {
        "last_update": zaman_muhru_uret(),
        "last_delivery": etiket,
        "next_step": sonraki_adim.strip() or "Gerektiginde yeni oturumu `bismillah` ile ac ve son teslim notundan devam et.",
        "handover": handover,
    }

    for satir in satirlar:
        eslesti = False
        for anahtar, deger in degerler.items():
            if satir.startswith(f"{anahtar}:"):
                yeni.append(f"{anahtar}: {deger}")
                eslesti = True
                break
        if not eslesti:
            yeni.append(satir)

    state_yolu.write_text("\n".join(yeni).rstrip() + "\n", encoding="utf-8")


def history_ekle(repo_kok, etiket, ref, ozet):
    history_yolu = repo_kok / "Besmele" / "HISTORY.md"
    yeni_satir = f"| {zaman_muhru_uret()} | {etiket} | teslim | {ref} | {ozet} |"
    satir_ekle(history_yolu, yeni_satir)


def task_log_ekle(repo_kok, ref, etiket, ozet):
    if not ref or ref == "NONE":
        return
    task_yolu = repo_kok / "Besmele" / "plans" / f"{ref}.md"
    if not task_yolu.exists():
        return

    satirlar = task_yolu.read_text(encoding="utf-8").splitlines()
    hedef_indeks = None
    for indeks, satir in enumerate(satirlar):
        if satir.strip() == "verification:":
            hedef_indeks = indeks
            while hedef_indeks > 0 and satirlar[hedef_indeks - 1].strip() == "":
                hedef_indeks -= 1
            break
    if hedef_indeks is None:
        return
    satirlar.insert(hedef_indeks, f"- {zaman_muhru_uret()} | {etiket} | {ozet}")
    task_yolu.write_text("\n".join(satirlar).rstrip() + "\n", encoding="utf-8")


def bundle_uret(repo_kok, proje_adi, bundle_dizini):
    bundle_dizini.mkdir(parents=True, exist_ok=True)
    bundle_adi = cikti_metni_uret("bundle", proje_adi, "", "bundle")
    bundle_yolu = bundle_dizini / bundle_adi
    sonuc = komut_calistir(["git", "bundle", "create", str(bundle_yolu), "--all"], repo_kok)
    return sonuc, bundle_yolu


def yerel_uzak_esit_mi(repo_kok, dal, uzak):
    yerel = komut_calistir(["git", "rev-parse", "HEAD"], repo_kok).stdout.strip()
    uzak_sonuc = komut_calistir(["git", "ls-remote", "--heads", uzak, dal], repo_kok).stdout.strip()
    uzak_sha = uzak_sonuc.split()[0] if uzak_sonuc else ""
    return yerel and yerel == uzak_sha, yerel, uzak_sha


def ana():
    arguman = ArgumentParser(description="Yedek/mola teslim noktasini tek akista uygular.")
    arguman.add_argument("--ozet", required=True, help="Kisa teslim/mola ozeti.")
    arguman.add_argument("--sonraki-adim", default="", help="Bir sonraki ilk adim.")
    arguman.add_argument("--kip", choices=["yedek", "mola"], default="yedek")
    arguman.add_argument("--repo", default=".", help="Repo kok yolu.")
    arguman.add_argument("--uzak", default="origin", help="Push icin uzak adi.")
    arguman.add_argument("--bundle-dizini", default="yedekler", help="Bundle klasoru.")
    secim = arguman.parse_args()

    repo_kok = Path(secim.repo).resolve()
    etiket = r_etiketi_uret()
    aktif_ref = state_degeri_oku(repo_kok, "active_task", "NONE")
    dal = komut_calistir(["git", "branch", "--show-current"], repo_kok).stdout.strip() or "main"

    try:
        aktif_oturum_temizle(repo_kok)
        state_guncelle(repo_kok, etiket, secim.sonraki_adim)
        history_ekle(repo_kok, etiket, aktif_ref, f"{secim.kip} | {secim.ozet.strip()}")
        task_log_ekle(repo_kok, aktif_ref, etiket, f"{secim.kip} | {secim.ozet.strip()}")

        komut_calistir(["git", "add", "-A"], repo_kok)
        commit_metni = f"{etiket} | {secim.ozet.strip()}"
        commit = komut_calistir(["git", "commit", "-m", commit_metni], repo_kok)
        if commit.returncode != 0 and "nothing to commit" not in (commit.stdout + commit.stderr).lower():
            raise RuntimeError(commit.stderr.strip() or commit.stdout.strip() or "commit basarisiz")

        push = komut_calistir(["git", "push", secim.uzak, dal], repo_kok)
        if push.returncode != 0:
            raise RuntimeError(push.stderr.strip() or push.stdout.strip() or "push basarisiz")

        bundle_sonuc, bundle_yolu = bundle_uret(repo_kok, repo_kok.name, repo_kok / secim.bundle_dizini)
        if bundle_sonuc.returncode != 0:
            raise RuntimeError(bundle_sonuc.stderr.strip() or bundle_sonuc.stdout.strip() or "bundle basarisiz")

        esit, yerel_sha, uzak_sha = yerel_uzak_esit_mi(repo_kok, dal, secim.uzak)
        print(f"TESLIM: {etiket}")
        print(f"PUSH: OK | dal={dal}")
        print(f"BUNDLE: {bundle_yolu}")
        print(f"ESITLIK: {'EVET' if esit else 'HAYIR'} | yerel={yerel_sha} | uzak={uzak_sha}")
        print("MOLA: Guvenli teslim noktasi olustu.")
    except Exception as hata:
        arsiv_etiketi = oturum_arsivi_yaz(
            repo_kok=repo_kok,
            ozet=secim.ozet,
            sonraki_adim=secim.sonraki_adim,
            ref=aktif_ref,
        )
        print(f"HATA: {hata}")
        print(f"OTURUM: {arsiv_etiketi} | Besmele/oturumlar/AKTIF_OTURUM.md")
        raise SystemExit(1)


if __name__ == "__main__":
    ana()
