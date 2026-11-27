"""Merchant adapter registry keyed by ``Merchant.adapter_key``."""

from app.scrapers.base import BaseScraper
from app.scrapers.compumarts import CompumartsScraper
from app.scrapers.nekhely import NekhelyScraper
from app.scrapers.sigma import SigmaScraper
from app.scrapers.twob import TwoBScraper

SCRAPERS: dict[str, type[BaseScraper]] = {
    scraper.key: scraper
    for scraper in (SigmaScraper, CompumartsScraper, NekhelyScraper, TwoBScraper)
}


def get_scraper(key: str) -> type[BaseScraper]:
    try:
        return SCRAPERS[key.casefold()]
    except KeyError as exc:
        raise ValueError(f"No scraper adapter registered for {key!r}") from exc


def available_scrapers() -> list[str]:
    return sorted(SCRAPERS)
