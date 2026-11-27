"""M2 ingestion tests: staging, dedupe, price-history policy, ghost inventory."""

from datetime import UTC, datetime, timedelta
from decimal import Decimal
from pathlib import Path

from sqlalchemy import func, select

from app.core.db import AsyncSession
from app.models.catalog import Offer, PriceHistory, Product
from app.models.scraping import MatchStatus, ParseStatus, RawSnapshot, StagingListing
from app.services.ingestion import recompute_offers, run_merchant

FIXTURES = Path(__file__).parent / "fixtures"
SIGMA_HTML = (FIXTURES / "sigma_listing.html").read_text(encoding="utf-8")


async def test_run_merchant_stages_and_dedupes(db: AsyncSession, seeded: None) -> None:
    run = await run_merchant(db, "sigma", html=SIGMA_HTML)
    assert run.status.value == "ok"
    assert run.snapshots_new == 1
    assert run.listings_parsed == 2

    snapshots = (await db.scalars(select(RawSnapshot))).all()
    assert len(snapshots) == 1
    assert snapshots[0].parse_status == ParseStatus.PARSED

    rows = (await db.scalars(select(StagingListing).order_by(StagingListing.id))).all()
    assert len(rows) == 2
    assert all(row.match_status == MatchStatus.AUTO_MATCHED for row in rows)
    assert rows[0].product_id is not None

    repeated = await run_merchant(db, "sigma", html=SIGMA_HTML)
    assert repeated.snapshots_new == 0
    assert len((await db.scalars(select(RawSnapshot))).all()) == 1
    assert len((await db.scalars(select(StagingListing))).all()) == 2


async def test_unmatched_listings_are_flagged_for_review(db: AsyncSession, seeded: None) -> None:
    unknown_html = SIGMA_HTML.replace("AMD Ryzen 5 7600", "Unknown Widget Pro")
    run = await run_merchant(db, "sigma", html=unknown_html)

    assert run.status.value == "partial"
    rows = (await db.scalars(select(StagingListing).order_by(StagingListing.id))).all()
    assert rows[0].match_status == MatchStatus.UNMATCHED
    assert rows[0].product_id is None
    assert rows[1].match_status == MatchStatus.AUTO_MATCHED


async def test_rejected_match_survives_a_later_scrape(db: AsyncSession, seeded: None) -> None:
    await run_merchant(db, "sigma", html=SIGMA_HTML)
    row = await db.scalar(select(StagingListing).where(StagingListing.external_id == "sigma-1"))
    assert row is not None
    row.match_status = MatchStatus.REJECTED
    row.product_id = None
    await db.flush()

    await run_merchant(db, "sigma", html=SIGMA_HTML.replace("8,900", "8,750"))
    await db.refresh(row)
    assert row.match_status == MatchStatus.REJECTED
    assert row.product_id is None


async def test_recompute_only_appends_history_on_change(db: AsyncSession, seeded: None) -> None:
    await run_merchant(db, "sigma", html=SIGMA_HTML)
    product = await db.scalar(select(Product).where(Product.slug == "ryzen-5-7600"))
    assert product is not None
    offer = await db.scalar(select(Offer).where(Offer.product_id == product.id))
    assert offer is not None

    first = await recompute_offers(db)
    assert first["offers_created"] == 0  # seeded catalog already has the offer
    assert first["offers_updated"] == 2
    assert first["history_added"] == 1  # the RTX fixture is out of stock; price is unchanged

    changed_html = SIGMA_HTML.replace("8,900", "8,750")
    await run_merchant(db, "sigma", html=changed_html)
    second = await recompute_offers(db)
    assert second["history_added"] == 1  # only the Ryzen price changed

    await db.refresh(offer)
    assert offer.price_egp == Decimal("8750.00")
    count = await db.scalar(
        select(func.count()).select_from(PriceHistory).where(PriceHistory.offer_id == offer.id)
    )
    assert count == 4  # 3 seeded points + 1 changed-price point


async def test_ghost_inventory_marks_stale_offers(db: AsyncSession, seeded: None) -> None:
    await run_merchant(db, "sigma", html=SIGMA_HTML)
    product = await db.scalar(select(Product).where(Product.slug == "ryzen-5-7600"))
    assert product is not None
    offer = await db.scalar(select(Offer).where(Offer.product_id == product.id))
    assert offer is not None

    now = datetime.now(UTC)
    offer.last_seen_at = now - timedelta(hours=48)
    rows = (await db.scalars(select(StagingListing))).all()
    for row in rows:
        row.match_status = MatchStatus.REJECTED  # nothing fresh for this product
    await db.flush()

    stats = await recompute_offers(db, now=now)
    assert stats["ghosts_marked"] == 1
    await db.refresh(offer)
    assert offer.in_stock is False

    ghost_point = await db.scalar(
        select(PriceHistory).where(
            PriceHistory.offer_id == offer.id, PriceHistory.source == "ghost"
        )
    )
    assert ghost_point is not None
    assert ghost_point.in_stock is False
