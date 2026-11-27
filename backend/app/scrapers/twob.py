"""2B (Magento) public category-page adapter.

2B's robots.txt allows clean category URLs and ``?p=N`` pagination only when it
is the sole query parameter. This adapter reads server-rendered category HTML,
never filter/sort/AJAX URLs and never cart/checkout paths. Its catalog is
laptop-heavy, so many staged listings are expected to stay unmatched.
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


class TwoBScraper(BaseScraper):
    key = "2b"
    base_url = "https://2b.com.eg"
    listings_url = f"{base_url}/en/computers/component.html"
    min_price_egp = Decimal("100")
    user_agents = ("Tagme3aPriceBot/1.0 (+https://github.com/Whiteman777/Tagme3a)",)

    category_paths: tuple[str, ...] = (
        "/en/computers/component.html",
        "/en/computers/component/build-your-pc/storage-solution.html",
        "/en/computers/storage/hard-drives.html",
        "/en/electronics/power/power-supply.html",
        "/en/gaming.html",
        "/en/computers/laptops.html",
    )
    max_pages: int = 6

    # Fallback for older/simple saved snapshots.
    selectors = Selectors(
        card="li.product-item",
        title="strong.product-item-name a.product-item-link",
        price='[data-price-type="finalPrice"] .price',
        link="a.product-item-link",
        stock=".product-status-messages",
        external_id_attr="data-product-id",
    )

    def listing_urls(self) -> list[str]:
        return [f"{self.base_url}{path}" for path in self.category_paths]

    def additional_pages(self, html: str, *, url: str) -> list[str]:
        """Follow Magento ``?p=N`` links, which robots.txt allows on their own."""
        document = LexborHTMLParser(html)
        current_path = urlparse(url).path
        try:
            current = int(parse_qs(urlparse(url).query).get("p", ["1"])[0])
        except ValueError:
            current = 1

        found: dict[int, str] = {}
        for link in document.css(".pages a[href]"):
            href = link.attributes.get("href", "")
            parsed = urlparse(href)
            if parsed.path != current_path or "&" in parsed.query:
                continue
            try:
                page = int(parse_qs(parsed.query).get("p", [""])[0])
            except ValueError:
                continue
            if current < page <= self.max_pages:
                found[page] = urljoin(url, href)
        return [found[page] for page in sorted(found)]

    def parse(self, html: str, *, url: str) -> list[ScrapedListing]:
        page_url = url or self.listings_url
        listings = self._parse_product_items(html, page_url=page_url)
        if listings:
            return listings
        return parse_cards(
            html,
            self.selectors,
            base_url=self.base_url,
            page_url=page_url,
            min_price_egp=self.min_price_egp,
        )

    def _parse_product_items(self, html: str, *, page_url: str) -> list[ScrapedListing]:
        document = LexborHTMLParser(html)
        listings: list[ScrapedListing] = []

        for card in document.css("li.product-item"):
            title_node = card.css_first("a.product-item-link")
            price_node = card.css_first('[data-price-type="finalPrice"] .price')
            if price_node is None:
                price_node = card.css_first(".price-box .price")
            if title_node is None or price_node is None:
                continue

            title = title_node.text(strip=True)
            price = parse_price_egp(price_node.text(strip=True))
            if not title or price is None or price < self.min_price_egp:
                continue

            id_node = card.css_first(".price-box[data-product-id]")
            external_id = id_node.attributes.get("data-product-id", "") if id_node else ""
            href = title_node.attributes.get("href", "")
            if not external_id and href:
                external_id = urlparse(href).path.rstrip("/").split("/")[-1]
            if not external_id:
                continue

            stock_node = card.css_first(".product-status-messages")
            stock_text = stock_node.text(strip=True) if stock_node is not None else None
            compare_node = card.css_first(".old-price .price")
            raw = {"title": title, "price": price_node.text(strip=True)}
            if compare_node is not None:
                compare_text = compare_node.text(strip=True)
                if compare_text:
                    raw["compare_at"] = compare_text
            if stock_text:
                raw["badges"] = stock_text

            brand, model = split_brand_model(title)
            listings.append(
                ScrapedListing(
                    external_id=external_id,
                    title=title,
                    url=urljoin(page_url, href) if href else "",
                    price_egp=price,
                    in_stock=is_in_stock(stock_text),
                    brand=brand,
                    model=model,
                    raw=raw,
                )
            )

        return listings
