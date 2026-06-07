#!/usr/bin/env python3
"""Repo-root launcher for the temporary daily content add desktop tool.

Usage:
  py add.py
  py add.py --ayah ".../ayetler.json" --hadith ".../hadisler.json"
"""

from __future__ import annotations

import runpy
from pathlib import Path


def main() -> None:
    script = Path(__file__).resolve().parent / "tools" / "content_review" / "add.py"
    runpy.run_path(str(script), run_name="__main__")


if __name__ == "__main__":
    main()
