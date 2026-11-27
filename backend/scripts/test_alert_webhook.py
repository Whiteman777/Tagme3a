"""Send a synthetic scraper alert to the configured ops webhook.

Use this after setting ``SCRAPER_ALERT_WEBHOOK_URL`` to confirm delivery before
relying on the daily cron. It uses the exact payload shape emitted by
``app.services.monitoring.emit_alerts``.

Run from ``backend/``::

    uv run python -m scripts.test_alert_webhook
"""

import argparse
import asyncio
import json

from app.core.config import settings
from app.schemas.scraping import ScraperAlert
from app.services.monitoring import post_alert_payload


def main() -> None:
    argparse.ArgumentParser(description=__doc__).parse_args()
    if not settings.SCRAPER_ALERT_WEBHOOK_URL:
        raise SystemExit("SCRAPER_ALERT_WEBHOOK_URL is not set")

    alert = ScraperAlert(
        merchant_key="compumarts",
        code="NO_RECENT_RUN",
        severity="warning",
        message="Synthetic connectivity test from scripts.test_alert_webhook.",
    )
    payload = {"alerts": [alert.model_dump(mode="json")]}
    print(json.dumps(payload, indent=2))

    delivered = asyncio.run(post_alert_payload(payload))
    if not delivered:
        raise SystemExit("Webhook delivery failed; check the webhook URL and network")
    print("Webhook delivered successfully.")


if __name__ == "__main__":
    main()
