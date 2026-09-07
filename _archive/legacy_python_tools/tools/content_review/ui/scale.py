from __future__ import annotations

UI_SCALE = 0.7


def scale(value: int) -> int:
    return max(1, round(value * UI_SCALE))


def pt(value: int) -> int:
    return max(8, round(value * UI_SCALE))
