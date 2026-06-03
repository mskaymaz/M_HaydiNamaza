#!/usr/bin/env python3
"""Local-only desktop content review/add tool (PySide6)."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

try:
    from PySide6.QtGui import QFont
    from PySide6.QtWidgets import QApplication, QMainWindow, QTabWidget
except ImportError:
    print("PySide6 not found.")
    print("Install command: py -m pip install PySide6")
    raise SystemExit(1)

from core.backup import BackupManager
from core.logger import ActionLogger
from core.models import AppPaths
from core.storage import ContentRepository
from ui.add_panel import AddPanel
from ui.review_panel import ReviewPanel


def _default_paths(repo_root: Path, tool_root: Path) -> AppPaths:
    return AppPaths(
        repo_root=repo_root,
        tool_root=tool_root,
        archive_ayah_path=repo_root / "Besmele" / "data" / "content_seed" / "ayahs.pending_review.v1.json",
        archive_hadith_path=repo_root / "Besmele" / "data" / "content_seed" / "hadiths.pending_review.v1.json",
        approved_ayah_path=repo_root / "assets" / "data" / "daily_content" / "approved" / "ayahs.v1.approved.json",
        approved_hadith_path=repo_root / "assets" / "data" / "daily_content" / "approved" / "hadiths.v1.approved.json",
        state_path=tool_root / "review_state.json",
        log_path=tool_root / "tool.log",
        backup_dir=tool_root / "backups",
    )


class MainWindow(QMainWindow):
    def __init__(self, repository: ContentRepository) -> None:
        super().__init__()
        self.setWindowTitle("İçerik İnceleme ve Ekleme Aracı")
        self.resize(1200, 860)
        tabs = QTabWidget()
        tabs.addTab(AddPanel(repository), "Ekle")
        tabs.addTab(ReviewPanel(repository), "Incele")
        tabs.setCurrentIndex(0)
        self.setCentralWidget(tabs)


def parse_args() -> argparse.Namespace:
    tool_root = SCRIPT_DIR
    repo_root = tool_root.parent.parent
    defaults = _default_paths(repo_root, tool_root)
    parser = argparse.ArgumentParser(description="Local daily ayah/hadith review+add desktop tool.")
    parser.add_argument("--ayah", default=str(defaults.archive_ayah_path), help="Archive ayah JSON path.")
    parser.add_argument("--hadith", default=str(defaults.archive_hadith_path), help="Archive hadith JSON path.")
    parser.add_argument("--approved-ayah", default=str(defaults.approved_ayah_path), help="Approved ayah JSON path.")
    parser.add_argument("--approved-hadith", default=str(defaults.approved_hadith_path), help="Approved hadith JSON path.")
    parser.add_argument("--state", default=str(defaults.state_path), help="Tool state JSON path.")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    tool_root = SCRIPT_DIR
    repo_root = tool_root.parent.parent
    paths = AppPaths(
        repo_root=repo_root,
        tool_root=tool_root,
        archive_ayah_path=Path(args.ayah).resolve(),
        archive_hadith_path=Path(args.hadith).resolve(),
        approved_ayah_path=Path(args.approved_ayah).resolve(),
        approved_hadith_path=Path(args.approved_hadith).resolve(),
        state_path=Path(args.state).resolve(),
        log_path=tool_root / "tool.log",
        backup_dir=tool_root / "backups",
    )
    logger = ActionLogger(paths.log_path)
    backup_manager = BackupManager(paths.backup_dir)
    repository = ContentRepository(paths, logger, backup_manager)
    app = QApplication(sys.argv)
    base_font = QFont(app.font())
    base_font.setPointSizeF(max(14.0, base_font.pointSizeF()))
    app.setFont(base_font)
    window = MainWindow(repository)
    window.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()

