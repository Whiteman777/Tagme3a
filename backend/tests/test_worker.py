"""M2 worker tests: job registration, cron schedule and scrape isolation."""

from types import SimpleNamespace
from typing import Any

from app.models.catalog import Merchant
from app.models.scraping import RunStatus
from app.workers import WorkerSettings, tasks


def test_worker_registers_jobs_and_daily_cron() -> None:
    assert {func.__name__ for func in WorkerSettings.functions} == {
        "scrape_all",
        "recompute_offers_job",
    }
    assert {(job.hour, job.minute) for job in WorkerSettings.cron_jobs} == {(2, 0), (2, 30)}


async def test_scrape_all_skips_unregistered_and_isolates_failures(
    monkeypatch: Any, session_factory: Any, seeded: None
) -> None:
    called: list[str] = []
    emitted: list[dict[str, list[Any]]] = []

    async def _add_legacy_merchant() -> None:
        async with session_factory() as session:
            session.add(
                Merchant(
                    key="legacy",
                    name="Legacy",
                    base_url="https://legacy.example",
                    adapter_key="legacy",
                )
            )
            await session.commit()

    await _add_legacy_merchant()

    async def fake_run_merchant(db: Any, key: str, **kwargs: Any) -> SimpleNamespace:
        called.append(key)
        if key == "sigma":
            raise RuntimeError("boom")
        return SimpleNamespace(status=RunStatus.PARTIAL)

    async def fake_recompute(db: Any, **kwargs: Any) -> dict[str, int]:
        return {"offers_updated": 3}

    async def fake_emit_alerts(by_merchant: dict[str, list[Any]], **kwargs: Any) -> int:
        emitted.append(by_merchant)
        return sum(len(items) for items in by_merchant.values())

    monkeypatch.setattr(tasks, "AsyncSessionLocal", session_factory)
    monkeypatch.setattr(tasks, "run_merchant", fake_run_merchant)
    monkeypatch.setattr(tasks, "recompute_offers", fake_recompute)
    monkeypatch.setattr(tasks, "emit_alerts", fake_emit_alerts)

    result = await tasks.scrape_all({})

    assert set(called) == {"sigma", "compumarts", "nekhely", "2b"}  # legacy has no adapter
    assert result["runs"]["sigma"] == "error: boom"
    assert result["runs"]["compumarts"] == "partial"
    assert result["offers"] == {"offers_updated": 3}
    assert emitted and set(emitted[0]) == {"sigma", "compumarts", "nekhely", "2b", "legacy"}
    assert all(items == [] for key, items in emitted[0].items() if key == "legacy")
    assert result["alerts"] == 4  # no runs were recorded by the fake scraper


async def test_recompute_job_delegates_to_service(monkeypatch: Any, session_factory: Any) -> None:
    seen: dict[str, bool] = {}

    async def fake_recompute(db: Any, **kwargs: Any) -> dict[str, int]:
        seen["called"] = True
        return {"ghosts_marked": 1}

    monkeypatch.setattr(tasks, "AsyncSessionLocal", session_factory)
    monkeypatch.setattr(tasks, "recompute_offers", fake_recompute)

    assert await tasks.recompute_offers_job({}) == {"ghosts_marked": 1}
    assert seen["called"] is True
