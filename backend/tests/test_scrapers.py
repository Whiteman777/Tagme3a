"""M2 scraper tests using saved HTML fixtures (no live network)."""

from decimal import Decimal
from pathlib import Path

import httpx
import pytest

from app.scrapers.base import is_in_stock, parse_price_egp
from app.scrapers.compumarts import CompumartsScraper
from app.scrapers.registry import available_scrapers, get_scraper
from app.scrapers.sigma import SigmaScraper

FIXTURES = Path(__file__).parent / "fixtures"


def test_price_and_stock_helpers() -> None:
    assert parse_price_egp("18,400 ج.م") == Decimal("18400")
    assert parse_price_egp("٨٩٠٠ ج.م") == Decimal("8900")
    assert parse_price_egp("4,300.00 EGP") == Decimal("4300.00")
    assert parse_price_egp("n/a") is None
    assert is_in_stock("In stock")
    assert not is_in_stock("Out of stock")
    assert not is_in_stock("نفد الكمية")


def test_sigma_fixture_parses_two_listings() -> None:
    html = (FIXTURES / "sigma_listing.html").read_text(encoding="utf-8")
    scraper = SigmaScraper(delay=0)
    listings = scraper.parse(html, url="https://sigma.com.eg/cpu")

    assert len(listings) == 2
    assert listings[0].external_id == "sigma-1"
    assert listings[0].price_egp == Decimal("8900")
    assert listings[0].url == "https://sigma.com.eg/products/ryzen-5-7600"
    assert listings[0].in_stock is True
    assert listings[1].price_egp == Decimal("31900")
    assert listings[1].in_stock is False


def test_compumarts_fixture_parses_two_listings() -> None:
    html = (FIXTURES / "compumarts_listing.html").read_text(encoding="utf-8")
    listings = CompumartsScraper(delay=0).parse(html, url="https://compumarts.com/components/cpu")

    assert len(listings) == 2
    assert listings[0].external_id == "cm-1"
    assert listings[0].price_egp == Decimal("18400.00")
    assert listings[0].url == "https://compumarts.com/en/products/rtx-4060-windforce"
    assert listings[1].in_stock is False


def test_registry_maps_merchant_adapter_keys() -> None:
    assert available_scrapers() == ["compumarts", "sigma"]
    assert get_scraper("sigma") is SigmaScraper
    assert get_scraper("compumarts") is CompumartsScraper
    with pytest.raises(ValueError, match="No scraper adapter"):
        get_scraper("unknown-merchant")


async def test_robots_disallow_blocks_fetch() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        if request.url.path == "/robots.txt":
            return httpx.Response(200, text="User-agent: *\nDisallow: /cpu\n")
        return httpx.Response(200, text="<html></html>")

    async with httpx.AsyncClient(
        transport=httpx.MockTransport(handler), base_url="https://sigma.com.eg"
    ) as client:
        scraper = SigmaScraper(delay=0, max_retries=0, client=client)
        with pytest.raises(PermissionError, match="robots.txt disallows"):
            await scraper.scrape("https://sigma.com.eg/cpu")
