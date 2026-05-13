#!/usr/bin/env python3
"""Local-only review tool for ayah/hadith draft content.

This script serves a minimal browser UI to review records one by one and mark:
- approved
- rejected
- pending

It never modifies source input files. Review progress is stored in a separate
state file, and exports are written under output/ with timestamped folders.
"""

from __future__ import annotations

import argparse
import json
import os
from dataclasses import dataclass
from datetime import datetime, timezone
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs, urlparse


VALID_STATUSES = {"approved", "rejected", "pending"}


@dataclass(frozen=True)
class InputConfig:
    ayah_path: Path
    hadith_path: Path


class ReviewStore:
    def __init__(self, root: Path, inputs: InputConfig, state_path: Path) -> None:
        self.root = root
        self.inputs = inputs
        self.state_path = state_path
        self.output_dir = root / "output"
        self.output_dir.mkdir(parents=True, exist_ok=True)

        ayah_records = self._read_json_array(inputs.ayah_path)
        hadith_records = self._read_json_array(inputs.hadith_path)

        self.records: list[dict[str, Any]] = []
        for rec in ayah_records:
            self.records.append(self._normalize_record(rec, "ayah"))
        for rec in hadith_records:
            self.records.append(self._normalize_record(rec, "hadith"))

        if not self.records:
            raise RuntimeError("No records found in input files.")

        self.state = self._load_or_init_state()
        self._save_state()

    @staticmethod
    def _read_json_array(path: Path) -> list[dict[str, Any]]:
        # utf-8-sig handles both BOM and non-BOM UTF-8 safely.
        with path.open("r", encoding="utf-8-sig") as f:
            data = json.load(f)
        if not isinstance(data, list):
            raise ValueError(f"Expected JSON array in {path}")
        return data

    @staticmethod
    def _normalize_record(record: dict[str, Any], dataset: str) -> dict[str, Any]:
        if "id" not in record:
            raise ValueError(f"Record missing id in dataset={dataset}")
        out = dict(record)
        out["_dataset"] = dataset
        out["_record_key"] = f"{dataset}:{record['id']}"
        return out

    def _load_or_init_state(self) -> dict[str, Any]:
        now = self._utc_now()
        if self.state_path.exists():
            with self.state_path.open("r", encoding="utf-8") as f:
                state = json.load(f)
            if not isinstance(state, dict):
                raise ValueError("review_state.json must be an object.")
        else:
            state = {
                "version": 1,
                "created_at": now,
                "updated_at": now,
                "cursor": 0,
                "input_files": {
                    "ayah": str(self.inputs.ayah_path),
                    "hadith": str(self.inputs.hadith_path),
                },
                "decisions": {},
            }

        state.setdefault("version", 1)
        state.setdefault("created_at", now)
        state.setdefault("updated_at", now)
        state.setdefault("cursor", 0)
        state.setdefault("input_files", {})
        state.setdefault("decisions", {})

        state["cursor"] = max(0, min(int(state["cursor"]), len(self.records) - 1))
        return state

    @staticmethod
    def _utc_now() -> str:
        return datetime.now(timezone.utc).replace(microsecond=0).isoformat()

    def _save_state(self) -> None:
        self.state["updated_at"] = self._utc_now()
        self._atomic_json_write(self.state_path, self.state)

    @staticmethod
    def _atomic_json_write(path: Path, data: Any) -> None:
        tmp = path.with_suffix(path.suffix + ".tmp")
        with tmp.open("w", encoding="utf-8", newline="\n") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            f.write("\n")
        os.replace(tmp, path)

    def summary(self) -> dict[str, int]:
        totals = {"approved": 0, "rejected": 0, "pending": 0}
        decisions = self.state.get("decisions", {})
        for rec in self.records:
            key = rec["_record_key"]
            status = decisions.get(key, {}).get("status", "pending")
            if status not in VALID_STATUSES:
                status = "pending"
            totals[status] += 1
        return totals

    def current_payload(self) -> dict[str, Any]:
        cursor = int(self.state["cursor"])
        rec = self.records[cursor]
        decisions = self.state.get("decisions", {})
        current_decision = decisions.get(rec["_record_key"], {"status": "pending", "note": ""})
        return {
            "cursor": cursor,
            "total": len(self.records),
            "record": rec,
            "decision": current_decision,
            "summary": self.summary(),
        }

    def move_cursor(self, direction: str) -> dict[str, Any]:
        cursor = int(self.state["cursor"])
        if direction == "next":
            cursor = min(cursor + 1, len(self.records) - 1)
        elif direction == "prev":
            cursor = max(cursor - 1, 0)
        elif direction == "first":
            cursor = 0
        elif direction == "last":
            cursor = len(self.records) - 1
        else:
            raise ValueError("Invalid direction.")
        self.state["cursor"] = cursor
        self._save_state()
        return self.current_payload()

    def set_decision(
        self, status: str, note: str = "", move_next: bool = False
    ) -> dict[str, Any]:
        if status not in VALID_STATUSES:
            raise ValueError("Invalid status.")
        cursor = int(self.state["cursor"])
        rec = self.records[cursor]
        key = rec["_record_key"]
        self.state["decisions"][key] = {
            "status": status,
            "note": note,
            "updated_at": self._utc_now(),
        }
        if move_next:
            self.state["cursor"] = min(cursor + 1, len(self.records) - 1)
        self._save_state()
        return self.current_payload()

    def export(self) -> dict[str, str]:
        ts = datetime.now().strftime("%Y%m%d_%H%M%S")
        target = self.output_dir / f"review_export_{ts}"
        if target.exists():
            suffix = 1
            while (self.output_dir / f"review_export_{ts}_{suffix}").exists():
                suffix += 1
            target = self.output_dir / f"review_export_{ts}_{suffix}"
        target.mkdir(parents=False, exist_ok=False)

        decisions = self.state.get("decisions", {})
        buckets: dict[str, list[dict[str, Any]]] = {"approved": [], "rejected": [], "pending": []}

        for rec in self.records:
            key = rec["_record_key"]
            decision = decisions.get(key, {})
            status = decision.get("status", "pending")
            if status not in VALID_STATUSES:
                status = "pending"
            clean_record = {k: v for k, v in rec.items() if not k.startswith("_")}
            clean_record["review_status"] = status
            if decision.get("note"):
                clean_record["review_note"] = decision["note"]
            buckets[status].append(clean_record)

        approved_path = target / "approved.json"
        rejected_path = target / "rejected.json"
        pending_path = target / "pending.json"
        decisions_path = target / "review_decisions.json"

        self._atomic_json_write(approved_path, buckets["approved"])
        self._atomic_json_write(rejected_path, buckets["rejected"])
        self._atomic_json_write(pending_path, buckets["pending"])
        self._atomic_json_write(
            decisions_path,
            {
                "exported_at": self._utc_now(),
                "state_file": str(self.state_path),
                "input_files": self.state.get("input_files", {}),
                "summary": self.summary(),
                "decisions": decisions,
            },
        )

        return {
            "directory": str(target),
            "approved": str(approved_path),
            "rejected": str(rejected_path),
            "pending": str(pending_path),
            "decisions": str(decisions_path),
        }


def html_page() -> str:
    return """<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Daily Content Review Tool</title>
  <style>
    :root { color-scheme: light; }
    body { font-family: Segoe UI, sans-serif; margin: 0; background: #f6f7fb; color: #1d2433; }
    .wrap { max-width: 1080px; margin: 0 auto; padding: 20px; }
    .card { background: #fff; border: 1px solid #dde3ef; border-radius: 12px; padding: 16px; margin-bottom: 14px; }
    .row { display: flex; gap: 10px; flex-wrap: wrap; align-items: center; }
    .muted { color: #5b6475; font-size: 13px; }
    button { border: 1px solid #c9d2e7; background: #fdfefe; border-radius: 8px; padding: 9px 12px; cursor: pointer; }
    button:hover { background: #f3f7ff; }
    .approve { border-color: #6dbd7f; background: #eaf8ef; }
    .reject { border-color: #e59a9a; background: #fff1f1; }
    .pending { border-color: #d4b16a; background: #fff9ee; }
    textarea { width: 100%; min-height: 68px; padding: 8px; border: 1px solid #ced6e7; border-radius: 8px; }
    pre { white-space: pre-wrap; background: #f8f9fd; border: 1px solid #e4e9f5; padding: 10px; border-radius: 8px; }
    h1 { margin: 0 0 8px; font-size: 22px; }
    h2 { margin: 0 0 8px; font-size: 18px; }
  </style>
</head>
<body>
  <div class="wrap">
    <h1>Günlük İçerik İnceleme Aracı</h1>
    <div class="muted">Bu araç yalnızca yerel çalışır. Kaynak JSON dosyalarını değiştirmez.</div>

    <div class="card">
      <div id="summary" class="row"></div>
      <div class="row" style="margin-top: 8px;">
        <button onclick="nav('first')">İlk</button>
        <button onclick="nav('prev')">Önceki</button>
        <button onclick="nav('next')">Sonraki</button>
        <button onclick="nav('last')">Son</button>
        <button onclick="runExport()">Çıktı Üret</button>
      </div>
    </div>

    <div class="card">
      <div id="meta" class="muted"></div>
      <h2 id="title"></h2>
      <div id="fields"></div>
    </div>

    <div class="card">
      <div class="row">
        <button class="approve" onclick="mark('approved')">approved</button>
        <button class="reject" onclick="mark('rejected')">rejected</button>
        <button class="pending" onclick="mark('pending')">pending</button>
        <label><input type="checkbox" id="autoNext" checked /> İşaretleyince sonraki kayda geç</label>
      </div>
      <div style="margin-top: 10px;">
        <label for="note">İnceleme notu</label>
        <textarea id="note" placeholder="Opsiyonel not"></textarea>
      </div>
      <div id="currentDecision" class="muted" style="margin-top: 8px;"></div>
    </div>
  </div>

  <script>
    async function getJSON(url, opts) {
      const res = await fetch(url, opts);
      if (!res.ok) {
        throw new Error(await res.text());
      }
      return await res.json();
    }

    function renderObj(title, value) {
      if (value === null || value === undefined) return '';
      if (typeof value === 'object') {
        return `<h3>${title}</h3><pre>${JSON.stringify(value, null, 2)}</pre>`;
      }
      return `<p><strong>${title}:</strong> ${String(value)}</p>`;
    }

    function render(data) {
      const s = data.summary;
      document.getElementById('summary').innerHTML =
        `<strong>Toplam: ${data.total}</strong>` +
        ` <span>approved: ${s.approved}</span>` +
        ` <span>rejected: ${s.rejected}</span>` +
        ` <span>pending: ${s.pending}</span>`;

      const r = data.record;
      const idx = data.cursor + 1;
      document.getElementById('meta').textContent = `Kayıt ${idx}/${data.total} | ${r._dataset}`;
      document.getElementById('title').textContent = `${r.id}`;

      const fields = [];
      for (const [k, v] of Object.entries(r)) {
        if (k.startsWith('_')) continue;
        fields.push(renderObj(k, v));
      }
      document.getElementById('fields').innerHTML = fields.join('');

      const decision = data.decision || {status: 'pending', note: ''};
      document.getElementById('currentDecision').textContent =
        `Mevcut durum: ${decision.status}${decision.updated_at ? ' | güncelleme: ' + decision.updated_at : ''}`;
      document.getElementById('note').value = decision.note || '';
    }

    async function refresh() {
      const data = await getJSON('/api/current');
      render(data);
    }

    async function nav(direction) {
      const data = await getJSON('/api/nav', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({direction})
      });
      render(data);
    }

    async function mark(status) {
      const note = document.getElementById('note').value || '';
      const move_next = document.getElementById('autoNext').checked;
      const data = await getJSON('/api/mark', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({status, note, move_next})
      });
      render(data);
    }

    async function runExport() {
      const data = await getJSON('/api/export', { method: 'POST' });
      alert('Çıktılar üretildi:\\n' + data.directory);
      await refresh();
    }

    refresh().catch(err => {
      alert('Hata: ' + err.message);
    });
  </script>
</body>
</html>
"""


class ReviewHandler(BaseHTTPRequestHandler):
    store: ReviewStore

    def do_GET(self) -> None:  # noqa: N802
        parsed = urlparse(self.path)
        if parsed.path == "/":
            return self._write_html(html_page())
        if parsed.path == "/api/current":
            return self._write_json(self.store.current_payload())
        return self._not_found()

    def do_POST(self) -> None:  # noqa: N802
        parsed = urlparse(self.path)
        if parsed.path == "/api/nav":
            data = self._read_json_body()
            direction = str(data.get("direction", "next"))
            payload = self.store.move_cursor(direction)
            return self._write_json(payload)
        if parsed.path == "/api/mark":
            data = self._read_json_body()
            status = str(data.get("status", "pending"))
            note = str(data.get("note", ""))
            move_next = bool(data.get("move_next", False))
            payload = self.store.set_decision(status=status, note=note, move_next=move_next)
            return self._write_json(payload)
        if parsed.path == "/api/export":
            export_paths = self.store.export()
            return self._write_json(export_paths)
        return self._not_found()

    def _read_json_body(self) -> dict[str, Any]:
        length = int(self.headers.get("Content-Length", "0"))
        raw = self.rfile.read(length) if length else b"{}"
        if not raw:
            return {}
        return json.loads(raw.decode("utf-8"))

    def _write_json(self, data: Any, status: int = HTTPStatus.OK) -> None:
        body = json.dumps(data, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _write_html(self, html: str) -> None:
        body = html.encode("utf-8")
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _not_found(self) -> None:
        self._write_json({"error": "not found"}, status=HTTPStatus.NOT_FOUND)

    def log_message(self, format: str, *args: Any) -> None:
        # Keep console output minimal.
        return


def parse_args() -> argparse.Namespace:
    root = Path(__file__).resolve().parent
    repo_root = root.parent.parent
    parser = argparse.ArgumentParser(
        description="Local daily ayah/hadith review tool.",
    )
    parser.add_argument("--host", default="127.0.0.1", help="Host to bind.")
    parser.add_argument("--port", type=int, default=8765, help="Port to bind.")
    parser.add_argument(
        "--ayah",
        default=str(repo_root / "Besmele" / "data" / "daily_panel" / "ayahs_draft.json"),
        help="Path to ayah draft JSON file.",
    )
    parser.add_argument(
        "--hadith",
        default=str(repo_root / "Besmele" / "data" / "daily_panel" / "hadiths_draft.json"),
        help="Path to hadith draft JSON file.",
    )
    parser.add_argument(
        "--state",
        default=str(root / "review_state.json"),
        help="Path to review state JSON file.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    root = Path(__file__).resolve().parent
    ayah_path = Path(args.ayah).resolve()
    hadith_path = Path(args.hadith).resolve()
    state_path = Path(args.state).resolve()

    if not ayah_path.exists():
        raise FileNotFoundError(f"Ayah input file not found: {ayah_path}")
    if not hadith_path.exists():
        raise FileNotFoundError(f"Hadith input file not found: {hadith_path}")

    store = ReviewStore(
        root=root,
        inputs=InputConfig(ayah_path=ayah_path, hadith_path=hadith_path),
        state_path=state_path,
    )

    handler_cls = type("BoundReviewHandler", (ReviewHandler,), {"store": store})
    server = ThreadingHTTPServer((args.host, args.port), handler_cls)
    url = f"http://{args.host}:{args.port}/"
    print(f"Review tool started: {url}")
    print(f"Input ayah file : {ayah_path}")
    print(f"Input hadith file: {hadith_path}")
    print(f"State file      : {state_path}")
    print("Press Ctrl+C to stop.")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
