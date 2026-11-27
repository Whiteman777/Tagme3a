"""Cron registration and arq's next-fire calculation."""

from datetime import UTC, datetime
from typing import Any, cast

import pytest
from arq.worker import Worker, default_queue_name

from app.core.config import settings
from app.workers import WorkerSettings, build_cron_jobs
from app.workers.tasks import recompute_offers_job, scrape_all


def test_worker_registers_both_jobs_and_crons() -> None:
    assert set(WorkerSettings.functions) == {scrape_all, recompute_offers_job}
    assert {job.coroutine for job in WorkerSettings.cron_jobs} == {
        scrape_all,
        recompute_offers_job,
    }


class _FakePool:
    """Minimal arq pool that records cron enqueues without Redis."""

    def __init__(self) -> None:
        self.enqueued: list[tuple[str, dict[str, Any]]] = []

    async def enqueue_job(self, name: str, **kwargs: Any) -> object:
        self.enqueued.append((name, kwargs))
        return object()


async def test_arq_enqueues_cron_jobs_when_due(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(settings, "SCRAPE_CRON_HOUR", 12)
    monkeypatch.setattr(settings, "SCRAPE_CRON_MINUTE", 7)
    monkeypatch.setattr(settings, "RECOMPUTE_CRON_MINUTE", 7)

    pool = _FakePool()
    worker = Worker(
        functions=[],
        cron_jobs=build_cron_jobs(),
        redis_pool=cast(Any, pool),
    )
    just_before = datetime(2026, 11, 27, 12, 6, 59, tzinfo=UTC)
    await worker.run_cron(just_before, delay=1.0)  # first heartbeat initialises next_run
    await worker.run_cron(just_before, delay=1.0)  # next heartbeat enqueues due jobs

    assert {name for name, _ in pool.enqueued} == {"cron:scrape_all", "cron:recompute_offers_job"}
    assert all(kwargs["_queue_name"] == default_queue_name for _, kwargs in pool.enqueued)


def test_cron_jobs_fire_at_configured_utc_times(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(settings, "SCRAPE_CRON_HOUR", 12)
    monkeypatch.setattr(settings, "SCRAPE_CRON_MINUTE", 7)
    monkeypatch.setattr(settings, "RECOMPUTE_CRON_MINUTE", 37)

    jobs = {job.coroutine.__name__: job for job in build_cron_jobs()}
    previous = datetime(2026, 11, 27, 12, 6, tzinfo=UTC)

    scrape_job = jobs["scrape_all"]
    scrape_job.calculate_next(previous)
    assert scrape_job.next_run is not None
    assert (scrape_job.next_run.hour, scrape_job.next_run.minute) == (12, 7)

    recompute_job = jobs["recompute_offers_job"]
    recompute_job.calculate_next(previous)
    assert recompute_job.next_run is not None
    assert (recompute_job.next_run.hour, recompute_job.next_run.minute) == (12, 37)
