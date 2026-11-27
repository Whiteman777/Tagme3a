"""Schemas for the M2 review queue, scraper health and manual jobs."""

from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field

from app.models.catalog import ProductCategory
from app.models.scraping import MatchStatus, RunStatus


class ReviewListing(BaseModel):
    id: int
    merchant_key: str
    external_id: str
    raw_title: str
    normalized_name: str | None
    brand: str | None
    model: str | None
    category: ProductCategory | None
    price_egp: Decimal
    in_stock: bool
    url: str
    match_status: MatchStatus
    match_confidence: Decimal | None
    product_id: int | None
    created_at: datetime


class ReviewPage(BaseModel):
    items: list[ReviewListing]
    total: int
    page: int
    page_size: int


class ListingMatchRequest(BaseModel):
    product_id: int = Field(gt=0)


class ScraperHealth(BaseModel):
    merchant_key: str
    adapter_key: str | None
    is_active: bool
    last_status: RunStatus | None
    last_run_at: datetime | None
    last_error: str | None
    failures_24h: int


class ScrapeJob(BaseModel):
    job_id: str
    status: str = "queued"
