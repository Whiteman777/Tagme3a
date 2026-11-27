"""Compumarts listing-page adapter."""

from app.scrapers.base import BaseScraper, ScrapedListing, Selectors, parse_cards


class CompumartsScraper(BaseScraper):
    key = "compumarts"
    base_url = "https://compumarts.com"
    listings_url = f"{base_url}/components/cpu"

    selectors = Selectors(
        card="article.product-card",
        title="h2.product-name",
        price=".current-price",
        link="a.product-link",
        stock=".stock-status",
        external_id_attr="data-id",
    )

    def parse(self, html: str, *, url: str) -> list[ScrapedListing]:
        return parse_cards(
            html, self.selectors, base_url=self.base_url, page_url=url or self.listings_url
        )
