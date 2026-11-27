"""Scraper health alerts: deterministic rules and optional webhook delivery."""

import json
from datetime import UTC, datetime, timedelta
from typing import Any

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.catalog import Merchant
from app.models.scraping import RunStatus, ScraperRun
from app.schemas.scraping import ScraperAlert
from app.services.monitoring import emit_alerts, evaluate_scraper_health


async def _merchant_id(db: AsyncSession, key: str) -> int:
    merchant = await db.scalar(select(Merchant).where(Merchant.key == key))
    assert merchant is not None
    return merchant.id


def _run(
    merchant_id: int,
    started_at: datetime,
    status: RunStatus,
    *,
    snapshots_new: int = 0,
    listings_parsed: int = 0,
    throttled_responses: int = 0,
    fetch_failures: int = 0,
    parse_failures: int = 0,
) -> ScraperRun:
    return ScraperRun(
        merchant_id=merchant_id,
        started_at=started_at,
        status=status,
        snapshots_new=snapshots_new,
        listings_parsed=listings_parsed,
        throttled_responses=throttled_responses,
        fetch_failures=fetch_failures,
        parse_failures=parse_failures,
    )


async def test_missing_runs_alert_only_for_registered_adapters(
    db: AsyncSession, seeded: None
) -> None:
    db.add(
        Merchant(
            key="legacy",
            name="Legacy",
            base_url="https://legacy.example",
            adapter_key="legacy",
        )
    )
    await db.flush()

    health = await evaluate_scraper_health(db)

    assert [alert.code for alert in health["sigma"].alerts] == ["NO_RECENT_RUN"]
    assert health["legacy"].alerts == []


async def test_failure_throttle_and_parse_counters_raise_alerts(
    db: AsyncSession, seeded: None
) -> None:
    now = datetime.now(UTC)
    merchant_id = await _merchant_id(db, "sigma")
    db.add_all(
        [
            _run(merchant_id, now - timedelta(hours=5), RunStatus.FAILED),
            _run(merchant_id, now - timedelta(hours=4), RunStatus.FAILED),
            _run(
                merchant_id,
                now - timedelta(hours=2),
                RunStatus.PARTIAL,
                snapshots_new=1,
                listings_parsed=10,
                throttled_responses=3,
                fetch_failures=2,
                parse_failures=2,
            ),
        ]
    )
    await db.flush()

    health = await evaluate_scraper_health(db)

    assert {alert.code for alert in health["sigma"].alerts} == {
        "FAILED_RUNS",
        "THROTTLED",
        "FETCH_FAILURES",
        "PARSE_FAILURES",
    }


async def test_zero_yield_and_listing_drop_signal_selector_drift(
    db: AsyncSession, seeded: None
) -> None:
    now = datetime.now(UTC)
    merchant_id = await _merchant_id(db, "sigma")
    db.add_all(
        [
            _run(
                merchant_id,
                now - timedelta(hours=6),
                RunStatus.PARTIAL,
                snapshots_new=1,
                listings_parsed=100,
            ),
            _run(
                merchant_id,
                now - timedelta(hours=4),
                RunStatus.PARTIAL,
                snapshots_new=1,
                listings_parsed=100,
            ),
            _run(
                merchant_id,
                now - timedelta(hours=2),
                RunStatus.PARTIAL,
                snapshots_new=1,
                listings_parsed=0,
            ),
        ]
    )
    await db.flush()

    health = await evaluate_scraper_health(db)

    assert {alert.code for alert in health["sigma"].alerts} == {
        "SELECTOR_DRIFT",
        "LISTING_DROP",
    }


async def test_emit_alerts_posts_json_when_webhook_configured(
    monkeypatch: Any,
) -> None:
    monkeypatch.setattr(settings, "SCRAPER_ALERT_WEBHOOK_URL", "https://alerts.example/hook")
    captured: list[dict[str, Any]] = []

    def handler(request: httpx.Request) -> httpx.Response:
        captured.append(json.loads(request.content))
        return httpx.Response(204)

    alerts = {
        "sigma": [
            ScraperAlert(
                merchant_key="sigma",
                code="NO_RECENT_RUN",
                severity="critical",
                message="No scrape completed in the last 24h.",
            )
        ]
    }
    async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
        assert await emit_alerts(alerts, client=client) == 1

    assert captured[0]["alerts"][0]["code"] == "NO_RECENT_RUN"
    assert captured[0]["alerts"][0]["severity"] == "critical"
