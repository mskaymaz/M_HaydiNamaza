from __future__ import annotations

from ..models import FetchResult
from .tanzil_ayah_provider import TanzilAyahProvider


class AyahFetcher:
    def __init__(self) -> None:
        self.provider = TanzilAyahProvider()

    def fetch_reference(self, normalized: dict[str, object]) -> FetchResult:
        return self.provider.fetch(normalized)
