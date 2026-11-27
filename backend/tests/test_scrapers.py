"""M2 scraper tests using saved HTML fixtures (no live network)."""

from decimal import Decimal
from pathlib import Path

import httpx
import pytest

from app.scrapers.base import is_in_stock, parse_price_egp
from app.scrapers.compumarts import CompumartsScraper
from app.scrapers.nekhely import NekhelyScraper
from app.scrapers.registry import available_scrapers, get_scraper
from app.scrapers.sigma import SigmaScraper
from app.scrapers.twob import TwoBScraper

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


def test_sigma_listing_urls_include_component_searches() -> None:
    urls = SigmaScraper().listing_urls()

    assert len(urls) == 9
    assert urls[0].startswith("https://sigma-computer.com/en/category/")
    assert any("q=graphics+card" in url for url in urls)
    assert any("q=ryzen+5+7600" in url for url in urls)
    assert all("/api/" not in url for url in urls)


def test_sigma_real_fixture_parses_server_rendered_cards() -> None:
    html = (FIXTURES / "sigma_listing_real.html").read_text(encoding="utf-8")
    scraper = SigmaScraper(delay=0)
    listings = scraper.parse(html, url=scraper.listings_url)

    assert len(listings) == 2
    assert listings[0].external_id.startswith("lenovo-ideapad-slim-3-15irh10")
    assert listings[0].price_egp == Decimal("41999")
    assert listings[0].in_stock is True
    assert listings[0].url.startswith("https://sigma-computer.com/en/item?id=")
    assert listings[1].price_egp == Decimal("63999")
    assert listings[1].in_stock is True


def test_sigma_real_fixture_detects_out_of_stock_badge() -> None:
    html = (FIXTURES / "sigma_listing_oos_real.html").read_text(encoding="utf-8")
    scraper = SigmaScraper(delay=0)
    listings = scraper.parse(html, url=scraper.listings_url)

    assert len(listings) == 2
    assert listings[0].external_id.startswith("dell-optiplex-7090-tower")
    assert listings[0].price_egp == Decimal("32000")
    assert listings[0].in_stock is False
    assert listings[0].raw["badges"] == "Out Of Stockasd"
    assert listings[1].in_stock is True


def test_compumarts_fixture_parses_two_listings() -> None:
    html = (FIXTURES / "compumarts_listing.html").read_text(encoding="utf-8")
    listings = CompumartsScraper(delay=0).parse(html, url="https://compumarts.com/components/cpu")

    assert len(listings) == 2
    assert listings[0].external_id == "cm-1"
    assert listings[0].price_egp == Decimal("18400.00")
    assert listings[0].url == "https://compumarts.com/en/products/rtx-4060-windforce"
    assert listings[1].in_stock is False


def test_compumarts_real_fixture_parses_sold_out_and_fresh() -> None:
    html = (FIXTURES / "compumarts_listing_real.html").read_text(encoding="utf-8")
    scraper = CompumartsScraper(delay=0)
    listings = scraper.parse(html, url=scraper.listings_url)

    assert len(listings) == 2
    assert listings[0].external_id == "7627647844501"
    assert listings[0].price_egp == Decimal("111360.00")
    assert listings[0].in_stock is False
    assert listings[0].brand == "INTEL"
    assert listings[1].external_id == "9193018917013"
    assert listings[1].price_egp == Decimal("51500.00")
    assert listings[1].in_stock is True
    assert listings[1].brand == "AMD"


def test_compumarts_gpu_real_fixture_parses_prices() -> None:
    html = (FIXTURES / "compumarts_gpu_real.html").read_text(encoding="utf-8")
    scraper = CompumartsScraper(delay=0)
    listings = scraper.parse(html, url=scraper.listings_url)

    assert len(listings) == 2
    assert listings[0].external_id == "9076193329301"
    assert listings[0].price_egp == Decimal("448890.00")
    assert listings[0].title.startswith("MSI GeForce RTX")
    assert listings[0].in_stock is False


def test_compumarts_skips_placeholder_prices() -> None:
    html = (FIXTURES / "compumarts_placeholder_price_real.html").read_text(encoding="utf-8")
    scraper = CompumartsScraper(delay=0)

    assert scraper.parse(html, url=scraper.listings_url) == []


def test_compumarts_uses_identifying_agent_and_public_collections() -> None:
    scraper = CompumartsScraper()

    assert all("Tagme3aPriceBot" in ua for ua in scraper.user_agents)
    urls = scraper.listing_urls()
    assert len(urls) == len(scraper.collection_handles)
    assert all(url.endswith("?page=1") for url in urls)
    assert all("/cart" not in url and "/checkout" not in url for url in urls)


def test_compumarts_discovers_pagination_from_html() -> None:
    html = """
    <nav aria-label="Pagination"><ul class="pagination js-pagination">
      <li><a class="pagination__page-link" href="/collections/pc-parts-ram-1?page=2">2</a></li>
      <li><a class="pagination__page-link" href="/collections/pc-parts-ram-1?page=4">4</a></li>
      <li><a class="pagination__page-link" href="/collections/pc-parts-ram-1?page=15">15</a></li>
    </ul></nav>
    """
    scraper = CompumartsScraper(delay=0)
    pages = scraper.additional_pages(
        html, url=f"{scraper.base_url}/collections/pc-parts-ram-1?page=1"
    )
    assert pages == [
        f"{scraper.base_url}/collections/pc-parts-ram-1?page=2",
        f"{scraper.base_url}/collections/pc-parts-ram-1?page=4",
    ]


def test_sigma_discovers_capped_pagination_from_html() -> None:
    html = r'3d:["$","$L3e",null,{"totalPages":562,"perPage":16}]'
    scraper = SigmaScraper(delay=0)
    pages = scraper.additional_pages(
        html, url="https://sigma-computer.com/en/search?q=ddr5&page=1"
    )
    assert pages == [f"https://sigma-computer.com/en/search?q=ddr5&page={n}" for n in (2, 3)]


async def test_fetch_honors_retry_after_on_429() -> None:
    attempts = 0

    def handler(request: httpx.Request) -> httpx.Response:
        nonlocal attempts
        if request.url.path == "/robots.txt":
            return httpx.Response(200, text="User-agent: *\nAllow: /")
        if request.url.path == "/en/search":
            attempts += 1
            if attempts == 1:
                return httpx.Response(429, headers={"Retry-After": "0"})
            return httpx.Response(200, text="<html>ok</html>")
        return httpx.Response(404)

    async with httpx.AsyncClient(
        transport=httpx.MockTransport(handler), base_url="https://sigma-computer.com"
    ) as client:
        scraper = SigmaScraper(delay=0, max_retries=2, client=client)
        fetched = await scraper.fetch("https://sigma-computer.com/en/search", client)

    assert attempts == 2
    assert fetched.status_code == 200


def test_nekhely_real_fixture_parses_cards_and_pagination() -> None:
    html = (FIXTURES / "nekhely_listing_real.html").read_text(encoding="utf-8")
    scraper = NekhelyScraper(delay=0)
    listings = scraper.parse(html, url=f"{scraper.base_url}/processors")

    assert len(listings) == 2
    assert listings[0].external_id == "2418"
    assert listings[0].price_egp == Decimal("23999")
    assert listings[0].brand == "AMD"
    assert listings[0].in_stock is True
    assert listings[0].url.startswith(f"{scraper.base_url}/processors/amd-ryzen-7-9800x3d")
    assert scraper.additional_pages(html, url=f"{scraper.base_url}/processors") == [
        f"{scraper.base_url}/processors?page={page}" for page in range(2, 7)
    ]


def test_fallback_parser_enforces_merchant_price_floor() -> None:
    html = """
    <div class="product-layout" data-product-id="999">
      <div class="caption">
        <div class="name"><a href="/ssd/placeholder">Placeholder SSD</a></div>
      </div>
      <div class="price"><span class="price-normal">1 L.E</span></div>
      <div class="stats"><span class="stat-2"><span>Out Of Stock</span></span></div>
    </div>
    """
    scraper = NekhelyScraper(delay=0)
    assert scraper.parse(html, url=f"{scraper.base_url}/ssd") == []


def test_nekhely_uses_live_store_domain() -> None:
    scraper = NekhelyScraper()
    assert scraper.base_url == "https://www.elnekhelytechnology.com"
    assert "elnekhely.com" not in scraper.base_url
    assert all("Tagme3aPriceBot" in ua for ua in scraper.user_agents)
    assert all("/checkout" not in url for url in scraper.listing_urls())


def test_twob_real_fixture_parses_server_rendered_prices() -> None:
    html = (FIXTURES / "twob_listing_real.html").read_text(encoding="utf-8")
    scraper = TwoBScraper(delay=0)
    listings = scraper.parse(html, url=f"{scraper.base_url}/en/computers/component.html")

    assert len(listings) == 2
    assert listings[0].external_id == "46792"
    assert listings[0].price_egp == Decimal("7499.00")
    assert listings[0].url.endswith("crucial-ram-16gb-ddr4-3200-mhz.html")
    assert listings[1].price_egp == Decimal("14999.00")


def test_twob_uses_clean_public_category_urls() -> None:
    scraper = TwoBScraper()
    assert all("Tagme3aPriceBot" in ua for ua in scraper.user_agents)
    urls = scraper.listing_urls()
    assert all(url.startswith(f"{scraper.base_url}/en/") for url in urls)
    assert all("?" not in url for url in urls)
    assert all(
        disallowed not in url
        for url in urls
        for disallowed in ("/checkout", "/cart", "/customer", "/catalogsearch")
    )


def test_registry_maps_merchant_adapter_keys() -> None:
    assert available_scrapers() == ["2b", "compumarts", "nekhely", "sigma"]
    assert get_scraper("sigma") is SigmaScraper
    assert get_scraper("compumarts") is CompumartsScraper
    assert get_scraper("nekhely") is NekhelyScraper
    assert get_scraper("2b") is TwoBScraper
    with pytest.raises(ValueError, match="No scraper adapter"):
        get_scraper("unknown-merchant")


async def test_robots_disallow_blocks_fetch() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        if request.url.path == "/robots.txt":
            return httpx.Response(200, text="User-agent: *\nDisallow: /en/category/cpu\n")
        return httpx.Response(200, text="<html></html>")

    async with httpx.AsyncClient(
        transport=httpx.MockTransport(handler), base_url="https://sigma-computer.com"
    ) as client:
        scraper = SigmaScraper(delay=0, max_retries=0, client=client)
        with pytest.raises(PermissionError, match="robots.txt disallows"):
            await scraper.scrape("https://sigma-computer.com/en/category/cpu")
