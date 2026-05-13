#!/usr/bin/env python3
"""Repo-root launcher for the temporary daily content review desktop tool.

Usage:
  py tool.py
  py tool.py --ayah ".../ayahs_draft.json" --hadith ".../hadiths_draft.json"
"""

from __future__ import annotations

import runpy
from pathlib import Path


def main() -> None:
    script = Path(__file__).resolve().parent / "tools" / "content_review" / "review_tool.py"
    runpy.run_path(str(script), run_name="__main__")


if __name__ == "__main__":
    main()
