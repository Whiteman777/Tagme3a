"""M2 admin review API tests: RBAC, match/reject, health and manual enqueue."""

from decimal import Decimal
from pathlib import Path
from typing import Any

from httpx import AsyncClient
from sqlalchemy import select

from app.api.deps import get_arq_pool
from app.core.db import AsyncSession
from app.main import app
from app.models.catalog import Offer, Product, ProductAlias
from app.models.scraping import MatchStatus, StagingListing
from app.services.ingestion import run_merchant
from app.services.matcher import match_listing

FIXTURES = Path(__file__).parent / "fixtures"
SIGMA_HTML = (FIXTURES / "sigma_listing.html").read_text(encoding="utf-8")


async def test_review_queue_requires_reviewer_role(client: AsyncClient, seeded: None) -> None:
    response = await client.get("/api/v1/admin/review/listings")
    assert response.status_code == 403


async def test_review_queue_allows_reviewer(
    reviewer_client: AsyncClient, seeded: None
) -> None:
    response = await reviewer_client.get("/api/v1/admin/review/listings")
    assert response.status_code == 200, response.text


async def test_review_list_filters_by_status_and_merchant(
    admin_client: AsyncClient, db: AsyncSession, seeded: None
) -> None:
    await run_merchant(db, "sigma", html=SIGMA_HTML)

    response = await admin_client.get(
        "/api/v1/admin/review/listings",
        params={"status": "auto_matched", "merchant": "sigma", "page": 1, "page_size": 1},
    )
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["total"] == 2
    assert body["page"] == 1
    assert body["page_size"] == 1
    assert len(body["items"]) == 1
    assert body["items"][0]["merchant_key"] == "sigma"
    assert body["items"][0]["match_status"] == "auto_matched"


async def test_match_promotes_listing_and_publishes_offer(
    admin_client: AsyncClient, db: AsyncSession, seeded: None
) -> None:
    unknown_html = SIGMA_HTML.replace("AMD Ryzen 5 7600", "Unknown Widget Pro")
    await run_merchant(db, "sigma", html=unknown_html)
    row = await db.scalar(
        select(StagingListing).where(StagingListing.raw_title == "Unknown Widget Pro")
    )
    assert row is not None
    assert row.match_status == MatchStatus.UNMATCHED

    product = await db.scalar(select(Product).where(Product.slug == "ryzen-5-7600"))
    assert product is not None

    response = await admin_client.post(
        f"/api/v1/admin/review/listings/{row.id}/match",
        json={"product_id": product.id},
    )
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["match_status"] == "matched"
    assert body["product_id"] == product.id

    await db.refresh(row)
    assert row.match_status == MatchStatus.MATCHED
    assert row.reviewed_by is not None

    offer = await db.scalar(
        select(Offer).where(Offer.product_id == product.id, Offer.merchant_id == row.merchant_id)
    )
    assert offer is not None
    assert offer.price_egp == Decimal("8900.00")


async def test_reviewer_match_learns_alias_for_future_scrapes(
    reviewer_client: AsyncClient, db: AsyncSession, seeded: None
) -> None:
    unknown_html = SIGMA_HTML.replace("AMD Ryzen 5 7600", "Unknown Widget Pro")
    await run_merchant(db, "sigma", html=unknown_html)
    row = await db.scalar(
        select(StagingListing).where(StagingListing.raw_title == "Unknown Widget Pro")
    )
    assert row is not None
    product = await db.scalar(select(Product).where(Product.slug == "ryzen-5-7600"))
    assert product is not None

    response = await reviewer_client.post(
        f"/api/v1/admin/review/listings/{row.id}/match",
        json={"product_id": product.id},
    )
    assert response.status_code == 200, response.text
    await db.refresh(row)
    assert row.reviewed_by is not None

    alias = await db.scalar(select(ProductAlias).where(ProductAlias.product_id == product.id))
    assert alias is not None
    assert alias.normalized == "unknown widget"

    learned = await match_listing(db, "Unknown Widget Pro")
    assert learned.status.value == "auto_matched"
    assert learned.product is not None and learned.product.id == product.id


async def test_reject_clears_product_match(
    admin_client: AsyncClient, db: AsyncSession, seeded: None
) -> None:
    await run_merchant(db, "sigma", html=SIGMA_HTML)
    row = await db.scalar(select(StagingListing).where(StagingListing.external_id == "sigma-1"))
    assert row is not None

    response = await admin_client.post(f"/api/v1/admin/review/listings/{row.id}/reject")
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["match_status"] == "rejected"
    assert body["product_id"] is None

    await db.refresh(row)
    assert row.match_status == MatchStatus.REJECTED
    assert row.product_id is None


async def test_scraper_health_reports_last_run(
    admin_client: AsyncClient, db: AsyncSession, seeded: None
) -> None:
    await run_merchant(db, "sigma", html=SIGMA_HTML)

    response = await admin_client.get("/api/v1/admin/scrapers/health")
    assert response.status_code == 200, response.text
    health = {item["merchant_key"]: item for item in response.json()}
    assert health["sigma"]["last_status"] == "ok"
    assert health["sigma"]["failures_24h"] == 0
    assert health["compumarts"]["last_status"] is None


async def test_admin_can_enqueue_manual_scrape(admin_client: AsyncClient, seeded: None) -> None:
    class FakeJob:
        job_id = "job-123"

    class FakePool:
        def __init__(self) -> None:
            self.job_name: str | None = None
            self.closed = False

        async def enqueue_job(self, name: str, *args: Any, **kwargs: Any) -> FakeJob:
            self.job_name = name
            return FakeJob()

        async def close(self) -> None:
            self.closed = True

    pool = FakePool()

    async def override_pool() -> Any:
        yield pool

    app.dependency_overrides[get_arq_pool] = override_pool

    response = await admin_client.post("/api/v1/admin/scrape/run")
    assert response.status_code == 202, response.text
    assert response.json() == {"job_id": "job-123", "status": "queued"}
    assert pool.job_name == "scrape_all"


async def test_manual_scrape_requires_admin(client: AsyncClient, seeded: None) -> None:
    response = await client.post("/api/v1/admin/scrape/run")
    assert response.status_code == 403
