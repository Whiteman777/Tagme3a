"""Deterministic scraper-health evaluation and alert emission.

Alerts are derived from `ScraperRun` counters only: no AI, no external scoring.
They are always logged and are optionally POSTed as JSON to a webhook.
"""

from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from statistics import median
from typing import Any

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.logging import logger
from app.models.catalog import Merchant
from app.models.scraping import RunStatus, ScraperRun
from app.schemas.scraping import ScraperAlert
from app.scrapers.registry import SCRAPERS

_WEEK_HOURS = 168


@dataclass(frozen=True)
class HealthSnapshot:
    """Per-merchant run metrics plus the alerts they trigger."""

    last_run: ScraperRun | None
    failures_24h: int
    throttles_24h: int
    fetch_failures_24h: int
    parse_failures_24h: int
    alerts: list[ScraperAlert]


def _utc(value: datetime) -> datetime:
    """SQLite can return naive timestamps; normalize before comparisons."""
    return value.replace(tzinfo=UTC) if value.tzinfo is None else value.astimezone(UTC)


async def evaluate_scraper_health(
    db: AsyncSession, *, now: datetime | None = None
) -> dict[str, HealthSnapshot]:
    """Evaluate all merchants from the last week of run history."""
    now = now or datetime.now(UTC)
    cutoff = now - timedelta(hours=settings.STALE_AFTER_HOURS)
    window = now - timedelta(hours=max(settings.STALE_AFTER_HOURS, _WEEK_HOURS))
    merchants = (await db.scalars(select(Merchant).order_by(Merchant.key))).all()
    result: dict[str, HealthSnapshot] = {}

    for merchant in merchants:
        runs = (
            await db.scalars(
                select(ScraperRun)
                .where(
                    ScraperRun.merchant_id == merchant.id,
                    ScraperRun.started_at >= window,
                )
                .order_by(ScraperRun.started_at.asc(), ScraperRun.id.asc())
            )
        ).all()
        last_run = runs[-1] if runs else None
        recent = [run for run in runs if _utc(run.started_at) >= cutoff]
        failed = [run for run in recent if run.status == RunStatus.FAILED]
        alerts: list[ScraperAlert] = []
        tracked = (merchant.adapter_key or merchant.key).casefold() in SCRAPERS

        def add(
            code: str,
            severity: str,
            message: str,
            *,
            key: str = merchant.key,
            bucket: list[ScraperAlert] = alerts,
        ) -> None:
            bucket.append(
                ScraperAlert(merchant_key=key, code=code, severity=severity, message=message)
            )

        if merchant.is_active and tracked:
            if last_run is None or _utc(last_run.started_at) < cutoff:
                add(
                    "NO_RECENT_RUN",
                    "critical",
                    f"No scrape completed in the last {settings.STALE_AFTER_HOURS}h.",
                )
            if len(failed) >= settings.SCRAPER_ALERT_FAILURE_LIMIT:
                add(
                    "FAILED_RUNS",
                    "critical",
                    f"{len(failed)} failed runs in the last {settings.STALE_AFTER_HOURS}h.",
                )

            throttles = sum(run.throttled_responses or 0 for run in recent)
            if throttles >= settings.SCRAPER_ALERT_THROTTLE_LIMIT:
                add("THROTTLED", "warning", f"{throttles} throttled responses; back off or review.")

            fetch_failures = sum(run.fetch_failures or 0 for run in recent)
            if fetch_failures >= settings.SCRAPER_ALERT_FAILURE_LIMIT:
                add(
                    "FETCH_FAILURES",
                    "warning",
                    f"{fetch_failures} pages failed to fetch; check robots/rate limits.",
                )

            parse_failures = sum(run.parse_failures or 0 for run in recent)
            if parse_failures >= settings.SCRAPER_ALERT_FAILURE_LIMIT:
                add(
                    "PARSE_FAILURES",
                    "warning",
                    f"{parse_failures} pages failed to parse; selectors may have drifted.",
                )

            new_runs = [
                run
                for run in recent
                if (run.snapshots_new or 0) > 0 and run.status in (RunStatus.OK, RunStatus.PARTIAL)
            ]
            if new_runs:
                latest = new_runs[-1]
                if (latest.listings_parsed or 0) == 0:
                    add(
                        "SELECTOR_DRIFT",
                        "warning",
                        "Latest new snapshots yielded zero listings; selectors may have drifted.",
                    )
                baseline_values = [
                    run.listings_parsed
                    for run in new_runs[:-1]
                    if (run.listings_parsed or 0) > 0
                ]
                if baseline_values and latest.listings_parsed < median(baseline_values) * (
                    settings.SCRAPER_ALERT_DROP_RATIO
                ):
                    add(
                        "LISTING_DROP",
                        "warning",
                        "Latest listing count dropped sharply against the 7-day median.",
                    )

        result[merchant.key] = HealthSnapshot(
            last_run=last_run,
            failures_24h=len(failed) if merchant.is_active else 0,
            throttles_24h=sum(run.throttled_responses or 0 for run in recent),
            fetch_failures_24h=sum(run.fetch_failures or 0 for run in recent),
            parse_failures_24h=sum(run.parse_failures or 0 for run in recent),
            alerts=alerts,
        )

    return result


async def post_alert_payload(
    payload: dict[str, Any], *, client: httpx.AsyncClient | None = None
) -> bool:
    """POST an alert payload to the configured webhook; never fail the caller."""
    if not settings.SCRAPER_ALERT_WEBHOOK_URL:
        return False

    own_client = client is None
    http = client or httpx.AsyncClient(timeout=5.0)
    try:
        response = await http.post(settings.SCRAPER_ALERT_WEBHOOK_URL, json=payload)
        response.raise_for_status()
        return True
    except httpx.HTTPError as exc:
        logger.error("scraper_alert_webhook_failed", error=str(exc))
        return False
    finally:
        if own_client:
            await http.aclose()


async def emit_alerts(
    by_merchant: dict[str, list[ScraperAlert]], *, client: httpx.AsyncClient | None = None
) -> int:
    """Log alerts and optionally POST them to ``SCRAPER_ALERT_WEBHOOK_URL``."""
    alerts = [alert for items in by_merchant.values() for alert in items]
    for alert in alerts:
        logger.warning(
            "scraper_alert",
            merchant=alert.merchant_key,
            code=alert.code,
            severity=alert.severity,
            message=alert.message,
        )
    if not alerts:
        return 0

    payload: dict[str, Any] = {
        "alerts": [alert.model_dump(mode="json") for alert in alerts],
    }
    await post_alert_payload(payload, client=client)
    return len(alerts)
