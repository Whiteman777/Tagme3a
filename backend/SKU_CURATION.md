# SKU curation workflow

Status: **reporting tooling ready; target SKU list required from the owner**.

The deterministic matcher can only match products present in the curated catalog.
With 15 development SKUs and 3,064 staged listings, most unmatched rows are
genuinely out-of-catalog (7600X, 4070 Ti, 8000 MT/s kits, H7 Flow, other board
vendors, 2B's laptop-heavy catalog) or bundles. Do not lower
`MATCH_AUTO_MIN=0.88` / `MATCH_REVIEW_MIN=0.72` to improve the raw rate: it would
publish wrong prices.

## Generate the shortlist

```bash
cd backend
uv run python -m scripts.sku_curation_report --format markdown --limit 50
uv run python -m scripts.sku_curation_report --format json > /tmp/sku-report.json
uv run python -m scripts.sku_curation_report --merchant sigma --min-count 2
```

The report groups `unmatched` and manually `matched` staging rows by merchant +
normalized title, with brand/model, observed EGP price range, any reviewer
suggestion, and a sample URL. Rejected rows are excluded. Auto-matched rows can
be included with `--status auto_matched` if desired.

## Curation steps

1. Review the highest-count groups first; repeated titles are the safest additions.
2. For each approved SKU, add the product through
   `POST /api/v1/admin/products` (admin token) with canonical name, brand, model,
   category, and price-relevant attributes (`capacity_gb`, `memory_speed_mts`,
   `variant`, etc.). See `M3.md` for the matcher's hard gates.
3. Let the next `scrape_all` or `recompute_offers_job` run re-evaluate staged
   listings. Manual `MATCHED`/`REJECTED` decisions are preserved.
4. Track the auto-match count before/after in `M3.md`'s verification section.

## Owner input still needed

Provide the target SKU shortlist (canonical names + brands/models + expected
categories) for the Egyptian market. Once supplied, products can be added and the
raw match rate measured again. No AI is used to invent SKUs, compatibility, or
ranking; additions are explicit curated content, with AR/EN phrasing handled
separately as copy only.
