#!/usr/bin/env python3
"""Repo-root launcher for the AllApp daily content publish tool.

Usage:
  py AllApp_push.py
"""

from __future__ import annotations

import runpy
from pathlib import Path


def main() -> None:
    script = (
        Path(__file__).resolve().parent
        / "tools"
        / "daily_content"
        / "allapp_push_tool.py"
    )
    runpy.run_path(str(script), run_name="__main__")


if __name__ == "__main__":
    main()
