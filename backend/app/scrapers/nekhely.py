"""Nekhely (OpenCart) public category-page adapter.

The seeded ``elnekhely.com`` domain is parked; the live store is
``elnekhelytechnology.com``. Its robots.txt allows category HTML and disallows
only one product URL (which this adapter never requests). Prices, stock and
product IDs are server-rendered, so no storefront API or JS browser is needed.
"""

from decimal import Decimal
from urllib.parse import parse_qs, urljoin, urlparse

from selectolax.lexbor import LexborHTMLParser

from app.scrapers.base import (
    BaseScraper,
    ScrapedListing,
    Selectors,
    is_in_stock,
    parse_cards,
    parse_price_egp,
    split_brand_model,
)


class NekhelyScraper(BaseScraper):
    key = "nekhely"
    base_url = "https://www.elnekhelytechnology.com"
    listings_url = f"{base_url}/processors"
    min_price_egp = Decimal("100")
    user_agents = ("Tagme3aPriceBot/1.0 (+https://github.com/Whiteman777/Tagme3a)",)

    category_paths: tuple[str, ...] = (
        "processors",
        "graphics-card",
        "motherboards",
        "ram",
        "ssd",
        "power-supply",
        "cases",
        "laptop",
    )
    max_pages: int = 6

    # Fallback for older/simple saved snapshots.
    selectors = Selectors(
        card="div.product-layout",
        title="div.caption div.name a",
        price=".price .price-normal",
        link="div.caption div.name a",
        stock="div.stats .stat-2 span:last-child",
        external_id_attr="data-product-id",
    )

    def listing_urls(self) -> list[str]:
        return [f"{self.base_url}/{path}" for path in self.category_paths]

    def additional_pages(self, html: str, *, url: str) -> list[str]:
        """Follow OpenCart's ``?page=N`` pagination links, capped per category."""
        document = LexborHTMLParser(html)
        current_path = urlparse(url).path
        try:
            current = int(parse_qs(urlparse(url).query).get("page", ["1"])[0])
        except ValueError:
            current = 1

        found: dict[int, str] = {}
        for link in document.css("ul.pagination a[href]"):
            href = link.attributes.get("href", "")
            parsed = urlparse(href)
            if parsed.path != current_path:
                continue
            try:
                page = int(parse_qs(parsed.query).get("page", [""])[0])
            except ValueError:
                continue
            if current < page <= self.max_pages:
                found[page] = urljoin(url, href)
        return [found[page] for page in sorted(found)]

    def parse(self, html: str, *, url: str) -> list[ScrapedListing]:
        page_url = url or self.listings_url
        listings = self._parse_product_layouts(html, page_url=page_url)
        if listings:
            return listings
        return parse_cards(
            html,
            self.selectors,
            base_url=self.base_url,
            page_url=page_url,
            min_price_egp=self.min_price_egp,
        )

    def _parse_product_layouts(self, html: str, *, page_url: str) -> list[ScrapedListing]:
        document = LexborHTMLParser(html)
        listings: list[ScrapedListing] = []

        for card in document.css("div.product-layout[data-product-id]"):
            title_node = card.css_first("div.caption div.name > a")
            price_node = card.css_first(".price .price-new")
            if price_node is None:
                price_node = card.css_first(".price .price-normal")
            if title_node is None or price_node is None:
                continue

            title = title_node.text(strip=True)
            price = parse_price_egp(price_node.text(strip=True))
            external_id = card.attributes.get("data-product-id", "")
            if not title or price is None or price < self.min_price_egp or not external_id:
                continue

            href = title_node.attributes.get("href", "")
            stock_node = card.css_first("div.stats .stat-2 span:last-child")
            stock_text = stock_node.text(strip=True) if stock_node is not None else None
            brand_node = card.css_first("div.stats .stat-1 a")
            brand = (
                brand_node.text(strip=True)
                if brand_node is not None
                else split_brand_model(title)[0]
            )
            compare_node = card.css_first(".price .price-old")
            raw = {"title": title, "price": price_node.text(strip=True)}
            if compare_node is not None:
                compare_text = compare_node.text(strip=True)
                if compare_text:
                    raw["compare_at"] = compare_text
            if stock_text:
                raw["stock"] = stock_text

            listings.append(
                ScrapedListing(
                    external_id=external_id,
                    title=title,
                    url=urljoin(page_url, href) if href else "",
                    price_egp=price,
                    in_stock=is_in_stock(stock_text),
                    brand=brand,
                    model=title,
                    raw=raw,
                )
            )

        return listings
