"""Sigma Computer listing-page adapter."""

from app.scrapers.base import BaseScraper, ScrapedListing, Selectors, parse_cards


class SigmaScraper(BaseScraper):
    key = "sigma"
    base_url = "https://sigma.com.eg"
    listings_url = f"{base_url}/cpu"

    selectors = Selectors(
        card="div.product-item",
        title=".product-title",
        price=".price",
        link="a",
        stock=".stock",
        external_id_attr="data-product-id",
    )

    def parse(self, html: str, *, url: str) -> list[ScrapedListing]:
        return parse_cards(
            html, self.selectors, base_url=self.base_url, page_url=url or self.listings_url
        )
