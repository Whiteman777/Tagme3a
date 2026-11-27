"""arq tasks for the M2 scraping pipeline."""

from typing import Any

from sqlalchemy import select

from app.core.db import AsyncSessionLocal
from app.core.logging import logger
from app.models.catalog import Merchant
from app.scrapers.registry import SCRAPERS
from app.services.ingestion import recompute_offers, run_merchant


async def scrape_all(ctx: dict[str, Any]) -> dict[str, Any]:
    """Scrape every active merchant that has a registered adapter.

    Each merchant is isolated: a failed fetch or parse is recorded as run health
    and never prevents the other merchants or the offer recompute from running.
    """
    async with AsyncSessionLocal() as db:
        merchants = (await db.scalars(select(Merchant).where(Merchant.is_active.is_(True)))).all()
        keys = [
            merchant.key
            for merchant in merchants
            if (merchant.adapter_key or merchant.key).casefold() in SCRAPERS
        ]

        runs: dict[str, str] = {}
        for key in keys:
            try:
                run = await run_merchant(db, key)
                runs[key] = run.status.value
            except Exception as exc:  # noqa: BLE001 - keep other merchants alive
                runs[key] = f"error: {exc}"
                logger.error("worker_merchant_failed", merchant=key, error=str(exc))

        stats = await recompute_offers(db)

    logger.info("worker_scrape_complete", runs=runs, **stats)
    return {"runs": runs, "offers": stats}


async def recompute_offers_job(ctx: dict[str, Any]) -> dict[str, int]:
    """Publish staged matches and mark ghost inventory without a fresh scrape."""
    async with AsyncSessionLocal() as db:
        return await recompute_offers(db)
