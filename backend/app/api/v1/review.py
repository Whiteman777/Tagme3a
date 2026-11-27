"""Reviewer/admin review queue, scraper health and manual scrape triggering."""

from datetime import UTC, datetime
from decimal import Decimal

from arq.connections import ArqRedis
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_arq_pool, get_current_admin, get_current_reviewer
from app.core.db import get_db
from app.models.catalog import Merchant, Product
from app.models.scraping import MatchStatus, StagingListing
from app.models.user import User
from app.schemas.scraping import (
    ListingMatchRequest,
    ReviewListing,
    ReviewPage,
    ScrapeJob,
    ScraperHealth,
)
from app.services.ingestion import recompute_offers
from app.services.matcher import learn_alias
from app.services.monitoring import evaluate_scraper_health

router = APIRouter(prefix="/admin", tags=["admin", "review"])


def _to_item(row: StagingListing, merchant_key: str) -> ReviewListing:
    return ReviewListing(
        id=row.id,
        merchant_key=merchant_key,
        external_id=row.external_id,
        raw_title=row.raw_title,
        normalized_name=row.normalized_name,
        brand=row.brand,
        model=row.model,
        category=row.category,
        price_egp=row.price_egp,
        in_stock=row.in_stock,
        url=row.url,
        match_status=row.match_status,
        match_confidence=row.match_confidence,
        product_id=row.product_id,
        suggested_product_id=row.suggested_product_id,
        suggestion_confidence=row.suggestion_confidence,
        suggestion_reason=row.suggestion_reason,
        created_at=row.created_at,
    )


async def _merchant_key(db: AsyncSession, merchant_id: int) -> str:
    return await db.scalar(select(Merchant.key).where(Merchant.id == merchant_id)) or ""


@router.get("/review/listings", response_model=ReviewPage)
async def list_review_listings(
    status_filter: MatchStatus | None = Query(default=None, alias="status"),
    merchant: str | None = Query(default=None),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=50, ge=1, le=200),
    db: AsyncSession = Depends(get_db),
    _reviewer: User = Depends(get_current_reviewer),
) -> ReviewPage:
    conditions = []
    if status_filter is not None:
        conditions.append(StagingListing.match_status == status_filter)
    if merchant:
        conditions.append(Merchant.key == merchant)

    count_stmt = select(func.count()).select_from(StagingListing).join(Merchant)
    rows_stmt = select(StagingListing, Merchant.key).join(Merchant)
    if conditions:
        count_stmt = count_stmt.where(*conditions)
        rows_stmt = rows_stmt.where(*conditions)

    total = await db.scalar(count_stmt)
    result = await db.execute(
        rows_stmt.order_by(StagingListing.created_at.desc(), StagingListing.id.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    items = [_to_item(row, key) for row, key in result.all()]
    return ReviewPage(items=items, total=int(total or 0), page=page, page_size=page_size)


@router.post("/review/listings/{listing_id}/match", response_model=ReviewListing)
async def match_listing(
    listing_id: int,
    data: ListingMatchRequest,
    db: AsyncSession = Depends(get_db),
    reviewer: User = Depends(get_current_reviewer),
) -> ReviewListing:
    row = await db.get(StagingListing, listing_id)
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Listing not found")

    product = await db.scalar(
        select(Product).where(Product.id == data.product_id, Product.is_active.is_(True))
    )
    if product is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Active product not found"
        )

    row.product_id = product.id
    row.category = product.category
    row.match_status = MatchStatus.MATCHED
    row.match_confidence = Decimal("1.0000")
    row.suggested_product_id = None
    row.suggestion_confidence = None
    row.suggestion_reason = None
    row.reviewed_by = reviewer.id
    row.reviewed_at = datetime.now(UTC)
    await learn_alias(
        db, product, row.normalized_name or row.raw_title, reviewed_by=reviewer.id
    )
    await db.flush()
    await recompute_offers(db)
    return _to_item(row, await _merchant_key(db, row.merchant_id))


@router.post("/review/listings/{listing_id}/reject", response_model=ReviewListing)
async def reject_listing(
    listing_id: int,
    db: AsyncSession = Depends(get_db),
    reviewer: User = Depends(get_current_reviewer),
) -> ReviewListing:
    row = await db.get(StagingListing, listing_id)
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Listing not found")

    row.match_status = MatchStatus.REJECTED
    row.product_id = None
    row.reviewed_by = reviewer.id
    row.reviewed_at = datetime.now(UTC)
    await db.flush()
    await recompute_offers(db)
    return _to_item(row, await _merchant_key(db, row.merchant_id))


@router.get("/scrapers/health", response_model=list[ScraperHealth])
async def scraper_health(
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(get_current_admin),
) -> list[ScraperHealth]:
    merchants = (await db.scalars(select(Merchant).order_by(Merchant.key))).all()
    snapshots = await evaluate_scraper_health(db)
    health: list[ScraperHealth] = []
    for merchant in merchants:
        snapshot = snapshots[merchant.key]
        last = snapshot.last_run
        health.append(
            ScraperHealth(
                merchant_key=merchant.key,
                adapter_key=merchant.adapter_key,
                is_active=merchant.is_active,
                last_status=last.status if last else None,
                last_run_at=last.started_at if last else None,
                last_error=last.error if last else None,
                failures_24h=snapshot.failures_24h,
                throttles_24h=snapshot.throttles_24h,
                fetch_failures_24h=snapshot.fetch_failures_24h,
                parse_failures_24h=snapshot.parse_failures_24h,
                alerts=snapshot.alerts,
            )
        )
    return health


@router.post("/scrape/run", response_model=ScrapeJob, status_code=status.HTTP_202_ACCEPTED)
async def trigger_scrape(
    _admin: User = Depends(get_current_admin),
    pool: ArqRedis = Depends(get_arq_pool),
) -> ScrapeJob:
    job = await pool.enqueue_job("scrape_all")
    if job is None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="The scrape job is already queued or running.",
        )
    return ScrapeJob(job_id=job.job_id)
