"""arq worker configuration (``arq app.workers.WorkerSettings``)."""

from arq.connections import RedisSettings
from arq.cron import CronJob, cron

from app.core.config import settings
from app.workers.tasks import recompute_offers_job, scrape_all


def build_cron_jobs() -> list[CronJob]:
    """Build cron jobs from current settings (kept callable for verification)."""
    return [
        cron(scrape_all, hour=settings.SCRAPE_CRON_HOUR, minute=settings.SCRAPE_CRON_MINUTE),
        cron(
            recompute_offers_job,
            hour=settings.SCRAPE_CRON_HOUR,
            minute=settings.RECOMPUTE_CRON_MINUTE,
        ),
    ]


class WorkerSettings:
    """Daily scrape + ghost-inventory recompute, plus on-demand jobs."""

    redis_settings = RedisSettings.from_dsn(str(settings.REDIS_URL))
    functions = [scrape_all, recompute_offers_job]
    cron_jobs = build_cron_jobs()
    max_jobs = 10
