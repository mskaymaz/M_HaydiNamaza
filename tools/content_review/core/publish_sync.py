from __future__ import annotations

import importlib.util
from pathlib import Path
from typing import Any


def sync_approved_publish(repo_root: Path) -> dict[str, Any]:
    script_path = repo_root / "tools" / "daily_content" / "sync_allapp_publish_from_approved.py"
    spec = importlib.util.spec_from_file_location("_daily_content_publish_sync", script_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Publish sync script yuklenemedi: {script_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.sync_publish_from_approved()
