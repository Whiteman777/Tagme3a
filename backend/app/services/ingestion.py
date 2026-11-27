"""Scrape → raw snapshot → staging → offers/price-history pipeline (M2)."""

import hashlib
from datetime import UTC, datetime, timedelta
from decimal import Decimal

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.logging import logger
from app.models.catalog import Merchant, Offer, PriceHistory, Product
from app.models.scraping import (
    MatchStatus,
    ParseStatus,
    RawSnapshot,
    RunStatus,
    ScraperRun,
    StagingListing,
)
from app.scrapers.base import FetchResult, ScrapedListing, slugify
from app.scrapers.registry import get_scraper


async def _match_product(
    db: AsyncSession, listing: ScrapedListing
) -> tuple[Product | None, Decimal | None]:
    """Deterministic M2 matching; fuzzy/pgvector matching arrives in M3."""
    title = listing.title.casefold()

    by_slug = await db.scalar(
        select(Product).where(Product.slug == slugify(listing.title), Product.is_active.is_(True))
    )
    if by_slug is not None:
        return by_slug, Decimal("0.99")

    products = (await db.scalars(select(Product).where(Product.is_active.is_(True)))).all()
    for product in products:
        if product.model.casefold() in title and (
            not listing.brand or product.brand.casefold() in title
        ):
            return product, Decimal("0.95")
    return None, None


def _finish_run(run: ScraperRun, started: datetime) -> None:
    now = datetime.now(UTC)
    run.finished_at = now
    run.duration_ms = int((now - started).total_seconds() * 1000)


async def run_merchant(
    db: AsyncSession,
    merchant_key: str,
    *,
    html: str | None = None,
    url: str | None = None,
    client: httpx.AsyncClient | None = None,
) -> ScraperRun:
    """Scrape one merchant and stage its listings.

    Passing ``html`` skips all network I/O and stages a single snapshot, which
    keeps the pipeline testable and lets operators reparse a retained snapshot.
    Live runs iterate ``scraper.listing_urls()`` so an adapter can cover several
    public pages (Sigma uses a category plus component searches).
    """
    merchant = await db.scalar(select(Merchant).where(Merchant.key == merchant_key))
    if merchant is None or not merchant.is_active:
        raise ValueError(f"Unknown or inactive merchant: {merchant_key}")

    scraper_type = get_scraper(merchant.adapter_key or merchant.key)
    started = datetime.now(UTC)
    run = ScraperRun(merchant_id=merchant.id, started_at=started, status=RunStatus.PARTIAL)
    db.add(run)
    await db.flush()

    scraper = scraper_type(
        delay=0 if html is not None else settings.SCRAPER_DELAY_SECONDS,
        timeout=settings.SCRAPER_TIMEOUT_SECONDS,
        max_retries=settings.SCRAPER_MAX_RETRIES,
        user_agents=tuple(settings.SCRAPER_USER_AGENTS),
        client=client,
    )
    if html is not None or url is not None:
        targets = [url or scraper_type.listings_url]
    else:
        targets = scraper.listing_urls()

    own_client = html is None and client is None
    http = client or (
        httpx.AsyncClient(timeout=settings.SCRAPER_TIMEOUT_SECONDS, follow_redirects=True)
        if own_client
        else None
    )

    total_found = 0
    total_matched = 0
    snapshots_new = 0
    failures: list[str] = []

    try:
        for target in targets:
            try:
                if html is not None:
                    fetched = FetchResult(
                        url=target,
                        html=html,
                        status_code=200,
                        checksum=hashlib.sha256(html.encode("utf-8")).hexdigest(),
                        fetched_at=started,
                    )
                else:
                    assert http is not None
                    fetched = await scraper.fetch(target, http)
            except Exception as exc:  # noqa: BLE001 - one page must not kill the batch
                failures.append(f"fetch {target}: {exc}")
                logger.error(
                    "scrape_fetch_failed", merchant=merchant_key, url=target, error=str(exc)
                )
                continue

            existing = await db.scalar(
                select(RawSnapshot).where(
                    RawSnapshot.merchant_id == merchant.id,
                    RawSnapshot.url == fetched.url,
                    RawSnapshot.checksum == fetched.checksum,
                )
            )
            if existing is not None:
                logger.info("scrape_unchanged", merchant=merchant_key, url=fetched.url)
                continue

            snapshot = RawSnapshot(
                merchant_id=merchant.id,
                url=fetched.url,
                checksum=fetched.checksum,
                content=fetched.html,
                status_code=fetched.status_code,
                parse_status=ParseStatus.PENDING,
                fetched_at=fetched.fetched_at,
            )
            db.add(snapshot)
            await db.flush()

            try:
                listings = scraper.parse(fetched.html, url=fetched.url)
            except Exception as exc:  # noqa: BLE001 - record the failure as run health
                snapshot.parse_status = ParseStatus.FAILED
                snapshot.error = str(exc)
                snapshot.parsed_at = datetime.now(UTC)
                failures.append(f"parse {fetched.url}: {exc}")
                logger.error(
                    "scrape_parse_failed",
                    merchant=merchant_key,
                    url=fetched.url,
                    error=str(exc),
                )
                continue

            matched = 0
            for listing in listings:
                product, confidence = await _match_product(db, listing)
                staging = await db.scalar(
                    select(StagingListing).where(
                        StagingListing.merchant_id == merchant.id,
                        StagingListing.external_id == listing.external_id,
                    )
                )
                if staging is None:
                    staging = StagingListing(
                        merchant_id=merchant.id, external_id=listing.external_id
                    )
                    db.add(staging)

                staging.raw_snapshot_id = snapshot.id
                staging.raw_title = listing.title
                staging.normalized_name = listing.title
                staging.brand = listing.brand
                staging.model = listing.model
                staging.price_egp = listing.price_egp
                staging.currency = listing.currency
                staging.in_stock = listing.in_stock
                staging.url = listing.url

                if product is not None:
                    staging.product_id = product.id
                    staging.category = product.category
                    staging.match_status = MatchStatus.AUTO_MATCHED
                    staging.match_confidence = confidence
                    matched += 1
                elif staging.match_status not in (MatchStatus.MATCHED, MatchStatus.AUTO_MATCHED):
                    staging.match_status = MatchStatus.UNMATCHED
                    staging.match_confidence = None
                    staging.product_id = None

            snapshot.parse_status = ParseStatus.PARSED
            snapshot.parsed_at = datetime.now(UTC)
            snapshots_new += 1
            total_found += len(listings)
            total_matched += matched
    finally:
        if own_client and http is not None:
            await http.aclose()

    run.listings_found = total_found
    run.listings_parsed = total_found
    run.snapshots_new = snapshots_new
    if failures:
        run.status = RunStatus.FAILED if snapshots_new == 0 else RunStatus.PARTIAL
        run.error = "; ".join(failures)
    elif unmatched := total_found - total_matched:
        run.status = RunStatus.PARTIAL
        run.error = f"{unmatched} listing(s) need review"
    else:
        run.status = RunStatus.OK
    _finish_run(run, started)
    await db.commit()
    logger.info(
        "scrape_staged",
        merchant=merchant_key,
        pages=len(targets),
        snapshots=snapshots_new,
        listings=total_found,
        matched=total_matched,
        status=run.status.value,
    )
    return run


async def recompute_offers(db: AsyncSession, *, now: datetime | None = None) -> dict[str, int]:
    """Publish matched staging rows to offers and append price history on change."""
    now = now or datetime.now(UTC)
    stats = {"offers_created": 0, "offers_updated": 0, "history_added": 0, "ghosts_marked": 0}

    rows = (
        await db.scalars(
            select(StagingListing).where(
                StagingListing.match_status.in_([MatchStatus.AUTO_MATCHED, MatchStatus.MATCHED]),
                StagingListing.product_id.is_not(None),
            )
        )
    ).all()

    seen_offer_ids: set[int] = set()
    for row in rows:
        assert row.product_id is not None
        offer = await db.scalar(
            select(Offer).where(
                Offer.product_id == row.product_id, Offer.merchant_id == row.merchant_id
            )
        )
        if offer is None:
            offer = Offer(
                product_id=row.product_id,
                merchant_id=row.merchant_id,
                url=row.url,
                price_egp=row.price_egp,
                in_stock=row.in_stock,
                match_confidence=row.match_confidence,
                first_seen_at=now,
                last_seen_at=now,
            )
            db.add(offer)
            await db.flush()
            stats["offers_created"] += 1
            changed = True
        else:
            changed = offer.price_egp != row.price_egp or offer.in_stock != row.in_stock
            offer.price_egp = row.price_egp
            offer.url = row.url
            offer.in_stock = row.in_stock
            offer.match_confidence = row.match_confidence
            offer.last_seen_at = now
            stats["offers_updated"] += 1

        seen_offer_ids.add(offer.id)
        if changed:
            db.add(
                PriceHistory(
                    offer_id=offer.id,
                    price_egp=row.price_egp,
                    in_stock=row.in_stock,
                    source="scraper",
                    captured_at=now,
                )
            )
            stats["history_added"] += 1

    cutoff = now - timedelta(hours=settings.STALE_AFTER_HOURS)
    offers = (await db.scalars(select(Offer).where(Offer.in_stock.is_(True)))).all()
    for offer in offers:
        if offer.id in seen_offer_ids or offer.last_seen_at is None:
            continue
        seen = offer.last_seen_at
        if seen.tzinfo is None:
            seen = seen.replace(tzinfo=UTC)
        if seen >= cutoff:
            continue
        offer.in_stock = False
        db.add(
            PriceHistory(
                offer_id=offer.id,
                price_egp=offer.price_egp,
                in_stock=False,
                source="ghost",
                captured_at=now,
            )
        )
        stats["ghosts_marked"] += 1

    await db.commit()
    logger.info("recompute_complete", **stats)
    return stats
