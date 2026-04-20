from argparse import ArgumentParser
from datetime import datetime
from pathlib import Path
import sys

arac_dizini = Path(__file__).resolve().parent
if str(arac_dizini) not in sys.path:
    sys.path.insert(0, str(arac_dizini))
from r_etiketi_uret import r_etiketi_uret


def zaman_muhru_uret(an=None):
    """zaman_muhru: HISTORY tablosunda kullanilan YYYY-MM-DD HH:MM +TZ bicimi."""
    zaman = an or datetime.now().astimezone()
    bolge = zaman.strftime("%z")
    bolge_kolonlu = f"{bolge[:3]}:{bolge[3:]}" if bolge else "+00:00"
    return f"{zaman.strftime('%Y-%m-%d %H:%M')} {bolge_kolonlu}"


def history_sablonu():
    return (
        "# BESMELE HISTORY\n\n"
        "Amac: Teslim, handover, snapshot ve kararlar icin tek append-only gecmis tutmak.\n\n"
        "| Date | Tag | Type | Ref | Summary |\n"
        "| --- | --- | --- | --- | --- |\n\n"
        "Ne zaman acilir?\n"
        "- Anlamli teslim, karar, snapshot veya handover kaydi ekleneceginde.\n"
    )


def satir_ekle(history_yolu, yeni_satir):
    satirlar = history_yolu.read_text(encoding="utf-8").splitlines()

    hedef_indeks = len(satirlar)
    for indeks, satir in enumerate(satirlar):
        if satir.strip().startswith("Ne zaman acilir?"):
            hedef_indeks = indeks
            while hedef_indeks > 0 and satirlar[hedef_indeks - 1].strip() == "":
                hedef_indeks -= 1
            break

    satirlar.insert(hedef_indeks, yeni_satir)
    history_yolu.write_text("\n".join(satirlar).rstrip() + "\n", encoding="utf-8")


def ana():
    varsayilan_history = Path(__file__).resolve().parents[1] / "HISTORY.md"

    arguman = ArgumentParser(description="HISTORY.md tablosuna tek komutla satir append eder.")
    arguman.add_argument("--tip", required=True, help="Kayit tipi: snapshot, handover, karar vb.")
    arguman.add_argument("--ref", required=True, help="Kayit referansi: TASK-xxx veya benzeri.")
    arguman.add_argument("--ozet", required=True, help="Kisa ozet metni.")
    arguman.add_argument("--etiket", default="", help="Bos birakilirsa R etiketi otomatik uretilir.")
    arguman.add_argument(
        "--dosya",
        default=str(varsayilan_history),
        help="HISTORY dosya yolu.",
    )
    secim = arguman.parse_args()

    history_yolu = Path(secim.dosya).resolve()
    history_yolu.parent.mkdir(parents=True, exist_ok=True)
    if not history_yolu.exists():
        history_yolu.write_text(history_sablonu(), encoding="utf-8")

    etiket = secim.etiket.strip() or r_etiketi_uret()
    ozet = secim.ozet.replace("|", "/").strip()
    yeni_satir = f"| {zaman_muhru_uret()} | {etiket} | {secim.tip.strip()} | {secim.ref.strip()} | {ozet} |"

    satir_ekle(history_yolu, yeni_satir)
    print(f"APPEND: {yeni_satir}")


if __name__ == "__main__":
    ana()
