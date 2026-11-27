"""Compumarts (Shopify) collection-page adapter.

Compumarts' ``agents.md`` asks agent traffic to identify itself, so this adapter
uses a dedicated bot User-Agent instead of a browser impersonation UA. It only
reads public collection HTML; cart/checkout and AJAX surfaces are off-limits.
"""

from decimal import Decimal
from urllib.parse import urljoin, urlparse

from selectolax.lexbor import LexborHTMLParser

from app.scrapers.base import (
    BaseScraper,
    ScrapedListing,
    Selectors,
    is_in_stock,
    parse_cards,
    parse_price_egp,
)


class CompumartsScraper(BaseScraper):
    key = "compumarts"
    base_url = "https://www.compumarts.com"
    min_price_egp = Decimal("100")
    listings_url = f"{base_url}/collections/pc-parts-proccesor"
    user_agents = ("Tagme3aPriceBot/1.0 (+https://github.com/Whiteman777/Tagme3a)",)

    collection_handles: tuple[str, ...] = (
        "pc-parts-proccesor",
        "pc-parts-graphic-card",
        "pc-parts-mother-board",
        "pc-parts-ram-1",
        "storage-ssd",
        "pc-parts-power-supply",
        "pc-parts-computer-cases",
        "prebuilt-desktop-pcs",
    )
    max_pages: int = 3

    # Fallback for older saved snapshots that used simple product cards.
    selectors = Selectors(
        card="article.product-card",
        title="h2.product-name",
        price=".current-price",
        link="a.product-link",
        stock=".stock-status",
        external_id_attr="data-id",
    )

    def listing_urls(self) -> list[str]:
        return [
            f"{self.base_url}/collections/{handle}?page={page}"
            for handle in self.collection_handles
            for page in range(1, self.max_pages + 1)
        ]

    def parse(self, html: str, *, url: str) -> list[ScrapedListing]:
        page_url = url or self.listings_url
        listings = self._parse_cards(html, page_url=page_url)
        if listings:
            return listings
        return parse_cards(html, self.selectors, base_url=self.base_url, page_url=page_url)

    def _parse_cards(self, html: str, *, page_url: str) -> list[ScrapedListing]:
        document = LexborHTMLParser(html)
        listings: list[ScrapedListing] = []

        for card in document.css("product-card"):
            title_node = card.css_first("p.card__title a.card-link")
            price_node = card.css_first(".price__current .js-value")
            if title_node is None or price_node is None:
                continue

            title = title_node.text(strip=True)
            price = parse_price_egp(price_node.text(strip=True))
            if not title or price is None or price < self.min_price_egp:
                continue

            href = title_node.attributes.get("href", "")
            id_node = card.css_first("[data-product-id]")
            external_id = (
                id_node.attributes.get("data-product-id", "") if id_node is not None else ""
            )
            if not external_id and href:
                external_id = urlparse(href).path.rstrip("/").split("/")[-1]
            if not external_id:
                continue

            sold_node = card.css_first(".product-label--sold-out")
            stock_text = sold_node.text(strip=True) if sold_node is not None else None
            vendor_node = card.css_first(".card__vendor")
            brand = vendor_node.text(strip=True) if vendor_node is not None else None
            compare_node = card.css_first(".price__was .js-value")
            raw = {"title": title, "price": price_node.text(strip=True)}
            if compare_node is not None:
                compare_text = compare_node.text(strip=True)
                if compare_text:
                    raw["compare_at"] = compare_text
            if stock_text:
                raw["badges"] = stock_text

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
