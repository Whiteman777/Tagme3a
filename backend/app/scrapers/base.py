"""Scraper primitives: fetching, robots.txt, throttling and HTML parsing."""

import asyncio
import hashlib
import itertools
import re
from abc import ABC, abstractmethod
from collections.abc import Iterator
from dataclasses import dataclass, field
from datetime import UTC, datetime
from decimal import Decimal, InvalidOperation
from email.utils import parsedate_to_datetime
from urllib.parse import parse_qsl, urlencode, urljoin, urlparse
from urllib.robotparser import RobotFileParser

import httpx
from selectolax.lexbor import LexborHTMLParser

from app.core.logging import logger

DEFAULT_USER_AGENTS: tuple[str, ...] = (
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/125.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0 Safari/537.36",
)

_ARABIC_DIGITS = str.maketrans("٠١٢٣٤٥٦٧٨٩", "0123456789")
_CURRENCY_MARKERS = ("ج.م", "جنيه", "جم", "EGP", "egp", "£")
_PRICE_RE = re.compile(r"\d+(?:\.\d{1,2})?")
_OUT_OF_STOCK = ("out of stock", "sold out", "unavailable", "نفد", "غير متوفر", "غير متاح")


def parse_price_egp(text: str | None) -> Decimal | None:
    """Parse Arabic/English price labels such as ``18,400 ج.م`` into EGP."""
    if not text:
        return None
    value = text.translate(_ARABIC_DIGITS)
    for marker in _CURRENCY_MARKERS:
        value = value.replace(marker, " ")
    value = value.replace("٫", ".").replace("٬", "").replace(",", "")
    match = _PRICE_RE.search(value)
    if match is None:
        return None
    try:
        return Decimal(match.group(0))
    except InvalidOperation:
        return None


def is_in_stock(text: str | None) -> bool:
    """Absence of a negative stock marker means in stock."""
    if not text:
        return True
    lowered = text.casefold()
    return not any(marker in lowered for marker in _OUT_OF_STOCK)


def slugify(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", text.casefold()).strip("-")


def split_brand_model(title: str) -> tuple[str | None, str | None]:
    """First token is treated as the brand; the rest is the model."""
    parts = title.split()
    if len(parts) >= 3:
        return parts[0], " ".join(parts[1:])
    return None, title or None


@dataclass(frozen=True)
class ScrapedListing:
    external_id: str
    title: str
    url: str
    price_egp: Decimal
    in_stock: bool = True
    brand: str | None = None
    model: str | None = None
    currency: str = "EGP"
    raw: dict[str, str] = field(default_factory=dict)


@dataclass(frozen=True)
class FetchResult:
    url: str
    html: str
    status_code: int
    checksum: str
    fetched_at: datetime


@dataclass(frozen=True)
class Selectors:
    """CSS selectors for one merchant's listing page (tune here when HTML changes)."""

    card: str
    title: str
    price: str
    link: str = "a"
    stock: str | None = None
    external_id_attr: str = "data-product-id"


def parse_cards(
    html: str,
    selectors: Selectors,
    *,
    base_url: str,
    page_url: str,
    min_price_egp: Decimal = Decimal("1"),
) -> list[ScrapedListing]:
    """Parse listing cards. Bad cards are skipped so one broken row cannot fail a batch."""
    document = LexborHTMLParser(html)
    listings: list[ScrapedListing] = []

    for card in document.css(selectors.card):
        title_node = card.css_first(selectors.title)
        price_node = card.css_first(selectors.price)
        if title_node is None or price_node is None:
            continue

        title = title_node.text(strip=True)
        price = parse_price_egp(price_node.text(strip=True))
        if not title or price is None or price < min_price_egp:
            continue

        link_node = card.css_first(selectors.link)
        href = link_node.attributes.get("href", "") if link_node is not None else ""
        url = urljoin(page_url or base_url, href) if href else ""
        path_id = urlparse(href).path.rstrip("/").split("/")[-1] if href else ""
        external_id = card.attributes.get(selectors.external_id_attr) or path_id or slugify(title)
        stock_node = card.css_first(selectors.stock) if selectors.stock else None
        brand, model = split_brand_model(title)

        listings.append(
            ScrapedListing(
                external_id=external_id,
                title=title,
                url=url,
                price_egp=price,
                in_stock=is_in_stock(stock_node.text(strip=True) if stock_node else None),
                brand=brand,
                model=model,
                raw={"title": title, "price": price_node.text(strip=True)},
            )
        )

    return listings


class BaseScraper(ABC):
    """HTTP fetch + parse contract shared by all merchant adapters."""

    key: str = ""
    base_url: str = ""
    listings_url: str = ""
    user_agents: tuple[str, ...] = ()
    min_price_egp: Decimal = Decimal("1")
    # Upper bound per seed URL so a broken/misleading page-count never causes an
    # unbounded crawl. Adapters override this when their real pages justify it.
    max_pages: int = 1
    max_retry_delay_seconds: float = 60.0

    def __init__(
        self,
        *,
        delay: float = 1.0,
        timeout: float = 15.0,
        max_retries: int = 2,
        user_agents: tuple[str, ...] | None = None,
        client: httpx.AsyncClient | None = None,
    ) -> None:
        self.delay = delay
        self.timeout = timeout
        self.max_retries = max_retries
        self._agents: Iterator[str] = itertools.cycle(
            user_agents or self.user_agents or DEFAULT_USER_AGENTS
        )
        self._client = client
        self._last_request: dict[str, datetime] = {}
        self._robots: dict[str, RobotFileParser | None] = {}

    def listing_urls(self) -> list[str]:
        """Public seed pages to scrape for this merchant (one by default)."""
        return [self.listings_url]

    def additional_pages(self, html: str, *, url: str) -> list[str]:
        """Discover follow-up pages from a seed page's HTML.

        Default is no pagination. Adapters return only public listing URLs they
        can justify from the fetched document; the ingestion loop dedupes them
        and applies ``max_pages`` as a safety cap.
        """
        return []

    @staticmethod
    def page_url(url: str, page: int) -> str:
        """Replace (or add) the ``page`` query parameter on a listing URL."""
        parsed = urlparse(url)
        query = [(key, value) for key, value in parse_qsl(parsed.query) if key != "page"]
        query.append(("page", str(page)))
        return f"{parsed._replace(query=urlencode(query)).geturl()}"

    @staticmethod
    def retry_after_seconds(value: str | None) -> float | None:
        """Parse Retry-After (delta-seconds or HTTP date) into a delay."""
        if not value:
            return None
        value = value.strip()
        if value.isdigit():
            return float(value)
        try:
            when = parsedate_to_datetime(value)
        except (TypeError, ValueError):
            return None
        if when.tzinfo is None:
            when = when.replace(tzinfo=UTC)
        return max(0.0, (when - datetime.now(UTC)).total_seconds())

    @abstractmethod
    def parse(self, html: str, *, url: str) -> list[ScrapedListing]:
        """Return listings from one HTML page."""

    async def _throttle(self, host: str) -> None:
        if self.delay <= 0:
            return
        last = self._last_request.get(host)
        if last is not None:
            elapsed = (datetime.now(UTC) - last).total_seconds()
            if elapsed < self.delay:
                await asyncio.sleep(self.delay - elapsed)
        self._last_request[host] = datetime.now(UTC)

    async def _robots_allowed(self, url: str, client: httpx.AsyncClient) -> bool:
        parsed = urlparse(url)
        origin = f"{parsed.scheme}://{parsed.netloc}"
        if origin not in self._robots:
            parser: RobotFileParser | None = RobotFileParser()
            parser.set_url(f"{origin}/robots.txt")
            try:
                response = await client.get(f"{origin}/robots.txt", timeout=5.0)
                if response.status_code == 200:
                    parser.parse(response.text.splitlines())
                else:
                    parser = None
            except httpx.HTTPError:
                parser = None
                logger.warning("robots_fetch_failed", origin=origin)
            self._robots[origin] = parser

        parser = self._robots[origin]
        return True if parser is None else parser.can_fetch(next(self._agents), url)

    async def fetch(self, url: str, client: httpx.AsyncClient) -> FetchResult:
        host = urlparse(url).netloc
        await self._throttle(host)
        if not await self._robots_allowed(url, client):
            raise PermissionError(f"robots.txt disallows {url}")

        last_error: Exception | None = None
        for attempt in range(self.max_retries + 1):
            try:
                response = await client.get(url, headers={"User-Agent": next(self._agents)})
                # agents.md asks bots to back off on 429 and honor Retry-After.
                if response.status_code in (429, 503) and attempt < self.max_retries:
                    delay = self.retry_after_seconds(response.headers.get("Retry-After"))
                    if delay is None:
                        delay = 0.5 * 2**attempt
                    last_error = RuntimeError(f"HTTP {response.status_code} from {url}")
                    logger.warning(
                        "scrape_backoff", merchant=self.key, url=url, status=response.status_code
                    )
                    await asyncio.sleep(min(delay, self.max_retry_delay_seconds))
                    continue
                response.raise_for_status()
                return FetchResult(
                    url=str(response.url),
                    html=response.text,
                    status_code=response.status_code,
                    checksum=hashlib.sha256(response.content).hexdigest(),
                    fetched_at=datetime.now(UTC),
                )
            except httpx.HTTPError as exc:
                last_error = exc
                if attempt < self.max_retries:
                    await asyncio.sleep(0.5 * 2**attempt)

        raise RuntimeError(f"Failed to fetch {url}: {last_error}") from last_error

    async def scrape(self, url: str | None = None) -> tuple[FetchResult, list[ScrapedListing]]:
        target = url or self.listings_url
        own_client = self._client is None
        client = self._client or httpx.AsyncClient(timeout=self.timeout, follow_redirects=True)
        try:
            fetched = await self.fetch(target, client)
            listings = self.parse(fetched.html, url=fetched.url)
            logger.info("scrape_complete", scraper=self.key, listings=len(listings))
            return fetched, listings
        finally:
            if own_client:
                await client.aclose()
