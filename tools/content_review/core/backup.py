from __future__ import annotations

import shutil
from datetime import datetime
from pathlib import Path


class BackupManager:
    def __init__(self, backup_dir: Path) -> None:
        self._backup_dir = backup_dir
        self._backup_dir.mkdir(parents=True, exist_ok=True)

    def create_backup(self, path: Path) -> Path | None:
        if not path.exists():
            return None
        stamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")
        backup_name = f"{path.name}.{stamp}.bak"
        backup_path = self._backup_dir / backup_name
        shutil.copy2(path, backup_path)
        return backup_path

    def restore_backup(self, backup_path: Path, target_path: Path) -> None:
        shutil.copy2(backup_path, target_path)

