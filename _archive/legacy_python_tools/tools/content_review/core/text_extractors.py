from __future__ import annotations

import re

_REFERENCE_CUE = (
    r"Buhar|Bukhari|Müslim|Muslim|Tirmiz|Tirmidhi|Nesai|Nasa'i|"
    r"Ebû|Ebu|Abu|Dâv|Davud|Dawud|Mâce|Majah|Ahmed|Ahmad|Dârim|Darimi|"
    r"Riyaz|Riyad|Mukaddime|Edeb|Mescid|Hac|Kehf|B\d|M\d|T\d|D\d|A\d"
)


def extract_trailing_reference(text: str, existing_ref: str = "") -> tuple[str, str]:
    work = str(text or "")
    refs: list[str] = []
    current_ref = str(existing_ref or "").strip()
    if current_ref:
        refs.append(current_ref)

    while True:
        match = re.match(
            r'(?s)^(.*?)(\s*([\(\[])([^()\[\]]{2,240})([\)\]])\s*[\.\!\?"]?\s*)$',
            work,
        )
        if not match:
            break
        inside = (match.group(4) or "").strip()
        if not inside or not re.search(_REFERENCE_CUE, inside, flags=re.IGNORECASE):
            break
        tail = (match.group(2) or "").strip()
        tail = re.sub(r'[\.\!\?"]\s*$', "", tail).strip()
        if tail.startswith("[") and tail.endswith("]"):
            tail = f"({tail[1:-1].strip()})"
        if tail and tail not in refs:
            refs.append(tail)
        work = (match.group(1) or "").rstrip()

    return work.strip(), "; ".join(refs).strip()
