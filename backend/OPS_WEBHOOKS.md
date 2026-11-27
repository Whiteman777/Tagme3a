# Ops alert webhook wiring

Status: **generic delivery implemented; provider URL still required from owner**.

`app.services.monitoring.emit_alerts()` always writes structured `scraper_alert`
logs. If `SCRAPER_ALERT_WEBHOOK_URL` is set, it also POSTs the same alert set as
JSON. Delivery failures are logged as `scraper_alert_webhook_failed` and never fail
a scrape. No credentials are stored in this repository.

## Payload

```json
{
  "alerts": [
    {
      "merchant_key": "compumarts",
      "code": "NO_RECENT_RUN",
      "severity": "warning",
      "message": "No scrape completed in the last 24h."
    }
  ]
}
```

Codes: `NO_RECENT_RUN`, `FAILED_RUNS`, `THROTTLED`, `FETCH_FAILURES`,
`PARSE_FAILURES`, `SELECTOR_DRIFT`, `LISTING_DROP`. See `M2.md` for triggers.

## Enable and test

```dotenv
SCRAPER_ALERT_WEBHOOK_URL=https://hooks.example.com/tagme3a-scraper-alerts
```

```bash
cd backend
uv run python -m scripts.test_alert_webhook
docker compose restart worker api
```

The script sends a synthetic `NO_RECENT_RUN` alert through the exact production
code path and exits non-zero on HTTP failure. A 2xx/204 response is required.

## Provider notes

- **Slack**: a plain incoming webhook expects `{"text": "..."}`, so either use a
  Slack Workflow Builder webhook step that maps `alerts[0].message` into the
  message, or put a small relay in front that converts the payload above. Do not
  paste a Slack webhook URL into git.
- **PagerDuty**: Events API v2 needs a `routing_key` and its own envelope, so use a
  relay that maps `severity` to `critical`/`warning` and sets `dedup_key` from
  `merchant_key + code`. The built-in payload is provider-neutral.
- **Email**: route the URL through a webhook-to-email service (e.g. Zapier/Make)
  and filter on `severity == "critical"` for on-call pages; warnings can be a
  daily digest.
- **Generic**: any HTTPS endpoint accepting `application/json` works as-is. Keep
  the endpoint public only if it validates a secret token/path.

## Owner action required

1. Choose the endpoint and, if needed, the relay/format mapping.
2. Set `SCRAPER_ALERT_WEBHOOK_URL` in the deployment environment (not in git).
3. Run `scripts.test_alert_webhook` and confirm the message arrives.
4. Record who owns the channel, the escalation path, and the review date.

Until step 3 succeeds, alerts remain visible only in worker/API logs via
`GET /api/v1/admin/scrapers/health` and structured `scraper_alert` entries.
