from __future__ import annotations

from PySide6.QtWidgets import QMessageBox, QWidget


def quiet_information(parent: QWidget | None, title: str, text: str) -> None:
    _show_quiet_box(parent, title, text)


def quiet_warning(parent: QWidget | None, title: str, text: str) -> None:
    _show_quiet_box(parent, title, text)


def quiet_critical(parent: QWidget | None, title: str, text: str) -> None:
    _show_quiet_box(parent, title, text)


def quiet_confirm(parent: QWidget | None, title: str, text: str) -> bool:
    result = _show_quiet_box(
        parent,
        title,
        text,
        buttons=QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No,
        default_button=QMessageBox.StandardButton.No,
    )
    return result == QMessageBox.StandardButton.Yes


def _show_quiet_box(
    parent: QWidget | None,
    title: str,
    text: str,
    *,
    buttons: QMessageBox.StandardButton = QMessageBox.StandardButton.Ok,
    default_button: QMessageBox.StandardButton = QMessageBox.StandardButton.Ok,
) -> QMessageBox.StandardButton:
    box = QMessageBox(parent)
    box.setIcon(QMessageBox.Icon.NoIcon)
    box.setWindowTitle(title)
    box.setText(text)
    box.setStandardButtons(buttons)
    box.setDefaultButton(default_button)
    return QMessageBox.StandardButton(box.exec())
