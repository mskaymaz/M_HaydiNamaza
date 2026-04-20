from argparse import ArgumentParser
from datetime import datetime
from pathlib import Path


def r_etiketi_uret(an=None):
    """r_etiketi: teslim ve handover kayitlarinda kullanilan R.yymmdd_hhmm etiketi."""
    zaman = an or datetime.now().astimezone()
    return f"R.{zaman.strftime('%y%m%d_%H%M')}"


def cikti_metni_uret(kip, proje, ozet, uzanti):
    """cikti_metni: secilen kip icin standart metin kalibi."""
    etiket = r_etiketi_uret()

    if kip == "etiket":
        return etiket
    if kip in {"commit", "push"}:
        return f"{etiket} | {ozet}"
    if kip == "bundle":
        return f"{proje}_{etiket}.bundle"
    return f"{proje}_{etiket}.{uzanti}"


def bagimsiz_yazim(ham_uzanti):
    """uzanti: release dosyasi icin noktasiz uzanti metni."""
    temiz = ham_uzanti.strip().lstrip(".")
    return temiz or "zip"


def ana():
    arguman = ArgumentParser(
        description="R etiketini ve commit/bundle/release icin standart ad metinlerini uretir."
    )
    arguman.add_argument(
        "--kip",
        choices=["etiket", "commit", "push", "bundle", "release"],
        default="etiket",
        help="Uretilecek metin tipi.",
    )
    arguman.add_argument(
        "--proje",
        default=Path.cwd().name or "proje",
        help="bundle/release adina yazilacak proje adi.",
    )
    arguman.add_argument(
        "--ozet",
        default="kisa not",
        help="commit/push metni icin ozet.",
    )
    arguman.add_argument(
        "--uzanti",
        default="zip",
        help="release kipinde kullanilan dosya uzantisi.",
    )
    secim = arguman.parse_args()
    print(
        cikti_metni_uret(
            kip=secim.kip,
            proje=secim.proje.strip() or "proje",
            ozet=secim.ozet.strip() or "kisa not",
            uzanti=bagimsiz_yazim(secim.uzanti),
        )
    )


if __name__ == "__main__":
    ana()
