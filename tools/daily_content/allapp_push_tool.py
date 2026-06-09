from __future__ import annotations

import json
import subprocess
import sys
import urllib.request
from datetime import datetime
from pathlib import Path
from typing import Any

try:
    from PySide6.QtCore import Qt, QThread, Signal
    from PySide6.QtWidgets import (
        QApplication,
        QGridLayout,
        QGroupBox,
        QHBoxLayout,
        QLabel,
        QMainWindow,
        QMessageBox,
        QPushButton,
        QTextEdit,
        QVBoxLayout,
        QWidget,
    )
except ImportError:
    print("PySide6 not found.")
    print("Install command: py -m pip install PySide6")
    raise SystemExit(1)


REPO_ROOT = Path(__file__).resolve().parents[2]
APPROVED_ROOT = REPO_ROOT / "assets" / "data" / "daily_content" / "approved"
ALLAPP_ROOT = REPO_ROOT / "_external" / "AllAppRemote"
ALLAPP_DATA_ROOT = ALLAPP_ROOT / "data" / "daily_content" / "v1"
REMOTE_BASE_URL = "https://raw.githubusercontent.com/mskaymaz/AllApp/main/data/daily_content/v1"
SYNC_SCRIPT = Path(__file__).resolve().with_name(
    "sync_allapp_publish_from_approved.py"
)


class PublishWorker(QThread):
    log = Signal(str)
    remote_counts = Signal(int, int, int)
    done = Signal(bool, str)

    def run(self) -> None:
        try:
            self._run()
        except Exception as exc:
            self.done.emit(False, str(exc))

    def _run(self) -> None:
        if not ALLAPP_ROOT.exists():
            raise RuntimeError(f"AllApp repo bulunamadi: {ALLAPP_ROOT}")
        if not (ALLAPP_ROOT / ".git").exists():
            raise RuntimeError(f"AllApp git repo degil: {ALLAPP_ROOT}")

        counts = read_counts()
        self.log.emit(
            f"Yerel approved: ayet={counts['ayah']}, hadis={counts['hadith']}, esma/sifat={counts['esma']}"
        )
        self._assert_allapp_dirty_scope_is_safe()

        self._run_command(
            [sys.executable, str(SYNC_SCRIPT)],
            cwd=REPO_ROOT,
            label="Yerel approved -> AllApp publish uretimi",
        )
        self._validate_generated_counts(counts)

        self._run_command(
            ["git", "add", "data/daily_content/v1"],
            cwd=ALLAPP_ROOT,
            label="AllApp publish dosyalari stage",
        )
        status = self._run_command(
            ["git", "status", "--porcelain"],
            cwd=ALLAPP_ROOT,
            label="AllApp degisiklik kontrolu",
            echo_output=False,
        ).strip()

        if status:
            stamp = datetime.now().strftime("%Y-%m-%d %H:%M")
            self._run_command(
                [
                    "git",
                    "commit",
                    "-m",
                    f"daily-content: sync local approved publish v1 {stamp}",
                ],
                cwd=ALLAPP_ROOT,
                label="AllApp commit",
            )
        else:
            self.log.emit("AllApp publish dosyalarinda yeni degisiklik yok.")

        self._run_command(
            ["git", "push", "origin", "main"],
            cwd=ALLAPP_ROOT,
            label="AllApp main push",
        )
        remote_counts = read_remote_counts()
        self.remote_counts.emit(
            remote_counts["ayah"],
            remote_counts["hadith"],
            remote_counts["esma"],
        )
        self.log.emit(
            f"Uzak yayin: ayet={remote_counts['ayah']}, hadis={remote_counts['hadith']}, esma/sifat={remote_counts['esma']}"
        )
        head = self._run_command(
            ["git", "rev-parse", "--short", "HEAD"],
            cwd=ALLAPP_ROOT,
            label="AllApp son commit",
            echo_output=False,
        ).strip()
        self.log.emit(f"AllApp remote guncellendi. Commit: {head}")
        self.done.emit(True, f"Yayin tamamlandi. Commit: {head}")

    def _assert_allapp_dirty_scope_is_safe(self) -> None:
        status = self._run_command(
            ["git", "status", "--porcelain"],
            cwd=ALLAPP_ROOT,
            label="AllApp on kontrol",
            echo_output=False,
        )
        unsafe = []
        for line in status.splitlines():
            path = line[3:].replace("\\", "/")
            if not path.startswith("data/daily_content/v1/"):
                unsafe.append(line)
        if unsafe:
            raise RuntimeError(
                "AllApp repo icinde daily_content disinda bekleyen degisiklik var:\n"
                + "\n".join(unsafe)
            )

    def _validate_generated_counts(self, expected: dict[str, int]) -> None:
        manifest = _read_json(ALLAPP_DATA_ROOT / "manifest.json")
        ayah = _read_json(ALLAPP_DATA_ROOT / "publish" / "ayahs.v1.approved.json")
        hadith = _read_json(
            ALLAPP_DATA_ROOT / "publish" / "hadiths.v1.approved.json"
        )
        esma = _read_json(
            ALLAPP_DATA_ROOT / "publish" / "esmaul_husna.v1.approved.json"
        )
        ayah_count = len(ayah.get("records", []))
        hadith_count = len(hadith.get("records", []))
        esma_count = len(esma.get("records", []))
        if (
            ayah_count != expected["ayah"]
            or hadith_count != expected["hadith"]
            or esma_count != expected["esma"]
        ):
            raise RuntimeError(
                "Uretilen AllApp kayit sayisi yerel approved ile eslesmiyor: "
                f"ayah={ayah_count}/{expected['ayah']}, "
                f"hadith={hadith_count}/{expected['hadith']}, "
                f"esma={esma_count}/{expected['esma']}"
            )
        self.log.emit(
            "AllApp manifest: "
            f"{manifest.get('content_version', '-')}; "
            f"ayet={ayah_count}, hadis={hadith_count}, esma/sifat={esma_count}"
        )

    def _run_command(
        self,
        command: list[str],
        *,
        cwd: Path,
        label: str,
        echo_output: bool = True,
    ) -> str:
        self.log.emit(f"> {label}")
        proc = subprocess.run(
            command,
            cwd=cwd,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        output = "\n".join(part for part in (proc.stdout, proc.stderr) if part)
        if echo_output and output.strip():
            self.log.emit(output.strip())
        if proc.returncode != 0:
            raise RuntimeError(
                f"{label} basarisiz oldu (exit={proc.returncode}).\n{output.strip()}"
            )
        return output


class AllAppPushWindow(QMainWindow):
    def __init__(self) -> None:
        super().__init__()
        self.worker: PublishWorker | None = None
        self.setWindowTitle("AllApp Daily Content Push")
        self.resize(780, 520)

        root = QWidget()
        layout = QVBoxLayout(root)

        summary = QGridLayout()
        self.local_ayah_count = QLabel("-")
        self.local_hadith_count = QLabel("-")
        self.local_esma_count = QLabel("-")
        self.remote_ayah_count = QLabel("-")
        self.remote_hadith_count = QLabel("-")
        self.remote_esma_count = QLabel("-")
        self.manifest_version = QLabel("-")
        self.allapp_path = QLabel(str(ALLAPP_ROOT))
        self.allapp_path.setTextInteractionFlags(Qt.TextSelectableByMouse)

        local_box = QGroupBox("Yuklenecek")
        local_layout = QGridLayout(local_box)
        local_layout.addWidget(QLabel("Onayli ayet"), 0, 0)
        local_layout.addWidget(self.local_ayah_count, 0, 1)
        local_layout.addWidget(QLabel("Onayli hadis"), 1, 0)
        local_layout.addWidget(self.local_hadith_count, 1, 1)
        local_layout.addWidget(QLabel("Onayli esma/sifat"), 2, 0)
        local_layout.addWidget(self.local_esma_count, 2, 1)

        remote_box = QGroupBox("Yayinda")
        remote_layout = QGridLayout(remote_box)
        remote_layout.addWidget(QLabel("Ayet"), 0, 0)
        remote_layout.addWidget(self.remote_ayah_count, 0, 1)
        remote_layout.addWidget(QLabel("Hadis"), 1, 0)
        remote_layout.addWidget(self.remote_hadith_count, 1, 1)
        remote_layout.addWidget(QLabel("Esma/Sifat"), 2, 0)
        remote_layout.addWidget(self.remote_esma_count, 2, 1)

        summary.addWidget(local_box, 0, 0)
        summary.addWidget(remote_box, 0, 1)
        summary.addWidget(QLabel("AllApp manifest"), 1, 0)
        summary.addWidget(self.manifest_version, 1, 1)
        summary.addWidget(QLabel("AllApp repo"), 2, 0)
        summary.addWidget(self.allapp_path, 2, 1)
        layout.addLayout(summary)

        buttons = QHBoxLayout()
        self.refresh_btn = QPushButton("Yenile")
        self.refresh_btn.clicked.connect(self.refresh_summary)
        self.push_btn = QPushButton("AllApp'a Push Et")
        self.push_btn.clicked.connect(self.publish)
        buttons.addStretch(1)
        buttons.addWidget(self.refresh_btn)
        buttons.addWidget(self.push_btn)
        layout.addLayout(buttons)

        self.log_box = QTextEdit()
        self.log_box.setReadOnly(True)
        layout.addWidget(self.log_box, 1)

        self.setCentralWidget(root)
        self.refresh_summary()

    def refresh_summary(self) -> None:
        try:
            counts = read_counts()
            self.local_ayah_count.setText(str(counts["ayah"]))
            self.local_hadith_count.setText(str(counts["hadith"]))
            self.local_esma_count.setText(str(counts["esma"]))
            manifest = _read_json(ALLAPP_DATA_ROOT / "manifest.json", default={})
            self.manifest_version.setText(str(manifest.get("content_version") or "-"))
            try:
                remote_counts = read_remote_counts()
                self._set_remote_counts(
                    remote_counts["ayah"],
                    remote_counts["hadith"],
                    remote_counts["esma"],
                )
            except Exception as exc:
                self._append_log(f"Uzak yayin sayisi okunamadi: {exc}")
            self._append_log("Ozet yenilendi.")
        except Exception as exc:
            self._append_log(f"Ozet okunamadi: {exc}")

    def publish(self) -> None:
        if self.worker is not None and self.worker.isRunning():
            return
        reply = QMessageBox.question(
            self,
            "AllApp'a push",
            "Yerel approved ayet/hadis/esma-sifat kayitlari AllApp publish dosyalarina yazilip GitHub main branch'e push edilecek. Devam edilsin mi?",
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No,
            QMessageBox.StandardButton.No,
        )
        if reply != QMessageBox.StandardButton.Yes:
            return

        self.push_btn.setEnabled(False)
        self.refresh_btn.setEnabled(False)
        self._append_log("Yayin akisi basladi.")
        self.worker = PublishWorker()
        self.worker.log.connect(self._append_log)
        self.worker.remote_counts.connect(self._set_remote_counts)
        self.worker.done.connect(self._publish_done)
        self.worker.start()

    def _set_remote_counts(
        self,
        ayah_count: int,
        hadith_count: int,
        esma_count: int,
    ) -> None:
        self.remote_ayah_count.setText(str(ayah_count))
        self.remote_hadith_count.setText(str(hadith_count))
        self.remote_esma_count.setText(str(esma_count))

    def _publish_done(self, ok: bool, message: str) -> None:
        self.push_btn.setEnabled(True)
        self.refresh_btn.setEnabled(True)
        self.refresh_summary()
        self._append_log(message)
        if ok:
            QMessageBox.information(self, "Tamam", message)
        else:
            QMessageBox.critical(self, "Hata", message)

    def _append_log(self, text: str) -> None:
        self.log_box.append(text)


def read_counts() -> dict[str, int]:
    return {
        "ayah": _record_count(APPROVED_ROOT / "ayahs.v1.approved.json"),
        "hadith": _record_count(APPROVED_ROOT / "hadiths.v1.approved.json"),
        "esma": _record_count(APPROVED_ROOT / "esmaul_husna.v1.approved.json"),
    }


def read_remote_counts() -> dict[str, int]:
    return {
        "ayah": _remote_record_count("publish/ayahs.v1.approved.json"),
        "hadith": _remote_record_count("publish/hadiths.v1.approved.json"),
        "esma": _remote_record_count("publish/esmaul_husna.v1.approved.json"),
    }


def _remote_record_count(path: str) -> int:
    url = f"{REMOTE_BASE_URL}/{path}"
    with urllib.request.urlopen(url, timeout=10) as response:
        payload = json.loads(response.read().decode("utf-8"))
    records = payload.get("records")
    if not isinstance(records, list):
        return 0
    return len(records)


def _record_count(path: Path) -> int:
    payload = _read_json(path)
    records = payload.get("records")
    if not isinstance(records, list):
        return 0
    return len(records)


def _read_json(path: Path, default: Any | None = None) -> Any:
    if not path.exists():
        if default is not None:
            return default
        raise FileNotFoundError(path)
    return json.loads(path.read_text(encoding="utf-8-sig"))


def main() -> None:
    app = QApplication(sys.argv)
    window = AllAppPushWindow()
    window.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
