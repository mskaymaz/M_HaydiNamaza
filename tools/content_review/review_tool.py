#!/usr/bin/env python3
"""Local-only desktop content review tool (PySide6)."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

try:
    from PySide6.QtCore import Qt
    from PySide6.QtGui import QFont
    from PySide6.QtWidgets import QApplication, QMainWindow, QScrollArea, QWidget
except ImportError:
    print("PySide6 not found.")
    print("Install command: py -m pip install PySide6")
    raise SystemExit(1)

from core.backup import BackupManager
from core.logger import ActionLogger
from core.models import AppPaths
from core.storage import ContentRepository
from ui.review_panel import ReviewPanel
from ui.scale import scale


def _default_paths(repo_root: Path, tool_root: Path) -> AppPaths:
    archive_root = repo_root / "assets" / "data" / "daily_content" / "archive"
    approved_root = repo_root / "assets" / "data" / "daily_content" / "approved"
    return AppPaths(
        repo_root=repo_root,
        tool_root=tool_root,
        archive_ayah_path=archive_root / "ayahs.pending_review.v1.json",
        archive_hadith_path=archive_root / "hadiths.pending_review.v1.json",
        archive_esma_path=archive_root / "esmaul_husna.pending_review.v1.json",
        approved_ayah_path=approved_root / "ayahs.v1.approved.json",
        approved_hadith_path=approved_root / "hadiths.v1.approved.json",
        approved_esma_path=approved_root / "esmaul_husna.v1.approved.json",
        state_path=tool_root / "review_state.json",
        log_path=tool_root / "tool.log",
        backup_dir=tool_root / "backups",
    )


class MainWindow(QMainWindow):
    def __init__(self, repository: ContentRepository) -> None:
        super().__init__()
        self.setWindowTitle("İçerik İnceleme Aracı")
        self.resize(scale(1200), 520)
        self.setCentralWidget(self._scrollable(ReviewPanel(repository)))

    @staticmethod
    def _scrollable(widget: QWidget) -> QScrollArea:
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        scroll.setWidget(widget)
        return scroll


def parse_args() -> argparse.Namespace:
    tool_root = SCRIPT_DIR
    repo_root = tool_root.parent.parent
    defaults = _default_paths(repo_root, tool_root)
    parser = argparse.ArgumentParser(description="Local daily ayah/hadith review desktop tool.")
    parser.add_argument("--ayah", default=str(defaults.archive_ayah_path), help="Archive ayah JSON path.")
    parser.add_argument("--hadith", default=str(defaults.archive_hadith_path), help="Archive hadith JSON path.")
    parser.add_argument("--esma", default=str(defaults.archive_esma_path), help="Archive esma JSON path.")
    parser.add_argument("--approved-ayah", default=str(defaults.approved_ayah_path), help="Approved ayah JSON path.")
    parser.add_argument("--approved-hadith", default=str(defaults.approved_hadith_path), help="Approved hadith JSON path.")
    parser.add_argument("--approved-esma", default=str(defaults.approved_esma_path), help="Approved esma JSON path.")
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
        archive_esma_path=Path(args.esma).resolve(),
        approved_ayah_path=Path(args.approved_ayah).resolve(),
        approved_hadith_path=Path(args.approved_hadith).resolve(),
        approved_esma_path=Path(args.approved_esma).resolve(),
        state_path=Path(args.state).resolve(),
        log_path=tool_root / "tool.log",
        backup_dir=tool_root / "backups",
    )
    logger = ActionLogger(paths.log_path)
    backup_manager = BackupManager(paths.backup_dir)
    repository = ContentRepository(paths, logger, backup_manager)
    app = QApplication(sys.argv)
    base_font = QFont(app.font())
    base_font.setPointSizeF(max(10.0, base_font.pointSizeF()))
    app.setFont(base_font)
    window = MainWindow(repository)
    window.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()

