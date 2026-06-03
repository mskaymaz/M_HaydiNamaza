from __future__ import annotations

from ..models import FetchResult
from .hadith_seed_provider import HadithSeedProvider


class HadithFetcher:
    def __init__(self) -> None:
        self.provider = HadithSeedProvider()

    def fetch(self, hadith_number: int) -> FetchResult:
        return self.provider.fetch(hadith_number)
