"""Sigma Computer listing-page adapter.

Sigma's public category pages are server-rendered Next.js HTML: each product card
has a titled ``/en/item?id=<slug>`` link, a ``p.font-bold`` price and a badge
container that shows ``Out Of Stock`` when needed. Parsing those cards keeps the
adapter independent of the site's internal API (which robots.txt disallows).
"""

from urllib.parse import parse_qs, unquote, urlencode, urljoin, urlparse

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


class SigmaScraper(BaseScraper):
    key = "sigma"
    base_url = "https://sigma-computer.com"
    listings_url = f"{base_url}/en/category/9f5039de-5c80-46f3-9fe4-6e8f94189b8c"  # Laptops

    # Public, robots-allowed searches that surface components (the category
    # redirect alone is laptop-heavy). Verified on real pages 2026-11-27.
    search_queries: tuple[str, ...] = (
        "ryzen 5 7600",
        "core i5 14600k",
        "ryzen 7 7800x3d",
        "graphics card",
        "motherboard",
        "ddr5",
        "ssd",
        "power supply",
    )

    # Fallback for older saved snapshots that used simple product cards.
    selectors = Selectors(
        card="div.product-item",
        title=".product-title",
        price=".price",
        link="a",
        stock=".stock",
        external_id_attr="data-product-id",
    )

    def listing_urls(self) -> list[str]:
        return [self.listings_url] + [
            f"{self.base_url}/en/search?{urlencode({'q': query})}" for query in self.search_queries
        ]

    def parse(self, html: str, *, url: str) -> list[ScrapedListing]:
        page_url = url or self.listings_url
        listings = self._parse_product_cards(html, page_url=page_url)
        if listings:
            return listings
        return parse_cards(html, self.selectors, base_url=self.base_url, page_url=page_url)

    @staticmethod
    def _card_for(anchor):
        """Walk up from a title link to the card that owns its price badge."""
        node = anchor
        for _ in range(8):
            node = node.parent
            if node is None:
                return None
            if node.css_first("p.font-bold") is not None:
                return node
        return None

    def _parse_product_cards(self, html: str, *, page_url: str) -> list[ScrapedListing]:
        document = LexborHTMLParser(html)
        listings: list[ScrapedListing] = []
        seen: set[str] = set()

        for anchor in document.css('a[title][href*="/en/item?id="]'):
            href = anchor.attributes.get("href", "")
            if not href:
                continue
            external_id = unquote(parse_qs(urlparse(href).query).get("id", [""])[0])
            if not external_id or external_id in seen:
                continue

            card = self._card_for(anchor)
            if card is None:
                continue
            price_node = card.css_first("p.font-bold")
            if price_node is None:
                continue
            price = parse_price_egp(price_node.text(strip=True))
            if price is None:
                continue

            title = anchor.attributes.get("title") or anchor.text(strip=True)
            if not title:
                continue
            badge = card.css_first("#badges-container")
            badges_text = badge.text(strip=True) if badge is not None else None
            compare_node = card.css_first("p.line-through")
            brand, model = split_brand_model(title)
            raw = {"title": title, "price": price_node.text(strip=True)}
            if compare_node is not None:
                raw["compare_at"] = compare_node.text(strip=True)
            if badges_text:
                raw["badges"] = badges_text

            seen.add(external_id)
            listings.append(
                ScrapedListing(
                    external_id=external_id,
                    title=title,
                    url=urljoin(page_url, href),
                    price_egp=price,
                    in_stock=is_in_stock(badges_text),
                    brand=brand,
                    model=model,
                    raw=raw,
                )
            )

        return listings
