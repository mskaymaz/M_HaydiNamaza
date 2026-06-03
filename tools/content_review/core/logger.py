from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


class ActionLogger:
    def __init__(self, path: Path) -> None:
        self._path = path
        self._path.parent.mkdir(parents=True, exist_ok=True)

    def log(self, action: str, **payload: Any) -> None:
        row = {
            "ts": datetime.now(timezone.utc).replace(microsecond=0).isoformat(),
            "action": action,
            **payload,
        }
        with self._path.open("a", encoding="utf-8", newline="\n") as handle:
            handle.write(json.dumps(row, ensure_ascii=False) + "\n")

