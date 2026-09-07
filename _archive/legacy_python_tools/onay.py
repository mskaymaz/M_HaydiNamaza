#!/usr/bin/env python3
"""Repo-root launcher for the approved content priority/delete tool.

Usage:
  py onay.py
"""

from __future__ import annotations

import runpy
from pathlib import Path


def main() -> None:
    script = (
        Path(__file__).resolve().parent
        / "tools"
        / "content_review"
        / "onay_tool.py"
    )
    runpy.run_path(str(script), run_name="__main__")


if __name__ == "__main__":
    main()
