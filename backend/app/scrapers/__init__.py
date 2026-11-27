"""Merchant scraper adapters."""

from app.scrapers.base import BaseScraper, ScrapedListing
from app.scrapers.registry import available_scrapers, get_scraper

__all__ = ["BaseScraper", "ScrapedListing", "available_scrapers", "get_scraper"]
