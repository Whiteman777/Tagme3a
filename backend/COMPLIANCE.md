# Merchant compliance and sign-off record

Status: **engineering checks complete; owner/legal approval pending**.

This file records the machine-checkable crawl constraints and the human approvals
still required before production scraping. `scripts/check_merchant_compliance.py`
re-reads live `robots.txt` and evaluates every seed URL with each adapter's real
User-Agent. Attach its output (JSON or Markdown) to each review.

```bash
cd backend
uv run python -m scripts.check_merchant_compliance --format markdown
uv run python -m scripts.check_merchant_compliance \
  --url https://www.compumarts.com/collections/pc-parts-proccesor?page=1
```

## Merchant matrix (observed 2026-11-27)

| Merchant | Adapter | Allowed paths used | UA | Signed traffic | Legal/commercial state |
|---|---|---|---|---|---|
| Sigma | `sigma` | `/en/*` category/search HTML only; never `/api/`, `/admin/`, checkout or account | identifying bot UA | not required by observed policy | No Terms page linked; footer only shows privacy/returns/shipping/warranty. **Owner/legal to confirm written permission.** |
| Compumarts | `compumarts` | `/collections/*` HTML only; cart/checkout/account/AJAX avoided | `Tagme3aPriceBot/1.0 (+https://github.com/Whiteman777/Tagme3a)` | RFC 9421 Web Bot Auth client implemented; disabled until owner publishes HTTPS JWK directory and worker gets the private key | `agents.md` asks bots to identify themselves and references UCP/MCP. **Owner to provide directory, allowlisting, and contact.** |
| Nekhely | `nekhely` | live store category HTML on `elnekhelytechnology.com`; one disallowed product URL never requested | identifying bot UA | not required by observed policy | Old `elnekhely.com` domain is parked. **Owner/legal to confirm store ownership and ToS.** |
| 2B | `twob` | clean `.html` categories and sole `?p=N`; filters/sorts/transactional paths avoided | `Tagme3aPriceBot/1.0` UA (named crawler UAs are blocked) | not required by observed policy | Laptop-heavy; 0 curated matches in the last smoke. **Owner/legal to confirm permission before relying on it.** |
| Amazon.eg | — | — | — | — | **Excluded.** Conditions of Use §3/§5 ban automated price collection into a database without written consent, and `/gp/offer-listing` is robots-disallowed. Do not re-add without written consent. |

## Owner/legal sign-off checklist

- [ ] Review the latest `check_merchant_compliance.py` output and confirm no adapter
      requests a disallowed path, a bot-blocked UA, or a transactional endpoint.
- [ ] Confirm each merchant's Terms of Service permits automated public price
      collection and storage in our EGP price-history database.
- [ ] For Compumarts: publish the public JWK directory over HTTPS, set
      `WEB_BOT_AUTH_AGENT_URL`/`WEB_BOT_AUTH_PRIVATE_KEY`, and confirm a live signed
      request is accepted. Record contact email, rotation owner, and expiry.
- [ ] Confirm crawl rate limits and stop conditions (`SCRAPER_DELAY_SECONDS`,
      `Retry-After`, `max_pages` caps: Sigma 3, Compumarts 14, 2B/Nekhely 6).
- [ ] Confirm retention of `raw_snapshots` HTML and the public opt-out/contact path.
- [ ] Confirm no personal data is collected from merchant pages.
- [ ] Record approver name, date, and merchants covered:
      `____________________ / __________ / ____________________`.

## Reproducing the engineering checks

All checks are deterministic and offline except the live robots fetch:

```bash
cd backend
DB_ECHO=false uv run ruff check .
DB_ECHO=false uv run pytest -q -p no:logging
uv run python -m scripts.check_merchant_compliance --format json > /tmp/robots-check.json
```

Matcher thresholds (`MATCH_AUTO_MIN=0.88`, `MATCH_REVIEW_MIN=0.72`,
`MATCH_VECTOR_DIMS=256`) are unchanged. Manual `MATCHED`/`REJECTED` decisions survive
later scrapes. No AI is used for compatibility, ranking, or merchant decisions.
