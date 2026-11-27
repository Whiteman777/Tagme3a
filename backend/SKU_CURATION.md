# SKU curation workflow

Status: **broad candidate CSV imported into the local dev DB; owner review and production import pending**.

The deterministic matcher can only match products present in the curated catalog.
With the 15 development SKUs, the four-merchant baseline was 22 auto-matches from
3,064 listings. After importing the broad candidate CSV into the local dev DB, one
full re-scrape auto-matched 3,079 of 3,149 listings (97.8%). Do not lower
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

## Generate the broad catalog candidate CSV

To cover every product type the project tracks — CPU, GPU, motherboard, RAM,
PSU, case, cooler, storage, laptop, prebuilt and peripheral — generate a
candidate CSV from the same robots-allowed public listing pages the scrapers
use:

```bash
cd backend
uv run python -m scripts.build_curated_sku_csv --output data/curated_skus_all.csv
```

This fetches only the registered adapters' public listing/pagination URLs with
the normal 1s politeness delay, groups identical normalized titles, and extracts
deterministic brand/category/spec/alias values. No AI invents products,
compatibility or rankings, and no database is touched.

The latest run produced `data/curated_skus_all.csv` with **2,998 candidate SKUs**
from 130 pages / 3,149 listings / 3,042 title groups:

| Category | Rows |
|---|---:|
| case | 403 |
| cooler | 14 |
| cpu | 267 |
| gpu | 549 |
| laptop | 259 |
| motherboard | 710 |
| peripheral | 64 |
| prebuilt | 10 |
| psu | 386 |
| ram | 205 |
| storage | 131 |

Counts will drift as merchant pages change. This file was imported into the local
development DB to measure match coverage, but it is still **review input**, not a
production-approved catalog: confirm names, specs and aliases before production
import.

## Add curated SKUs

Fill `data/curated_skus_template.csv` with owner-approved rows, then validate it
without touching Postgres:

```bash
cd backend
uv run python -m scripts.import_curated_skus \
  --file /path/to/skus.csv --dry-run
```

Each row becomes one canonical product plus optional curated aliases. Important
columns:

- Required: `slug`, `category`, `brand`, `model`, `name`.
- Optional: `name_ar`, `description`, `image_url`, `specs_json`, `aliases`.
- `category` is one of `cpu`, `gpu`, `motherboard`, `ram`, `psu`, `case`,
  `cooler`, `storage`, `laptop`, `prebuilt`, `peripheral`.
- `specs_json` must be a JSON object. Include price-relevant attributes the
  matcher gates on, e.g. `{"capacity_gb": 32, "speed": 6400}` for RAM or
  `{"vram": "16GB", "tdp": 285}` for a GPU.
- `aliases` are pipe-separated merchant title variants. They are curated text,
  not AI-generated.

Example row; quote the JSON because it contains commas:

```csv
slug,category,brand,model,name,name_ar,description,image_url,specs_json,aliases
rtx-4070-ti-super,gpu,MSI,RTX 4070 Ti SUPER Ventus,MSI GeForce RTX 4070 Ti SUPER Ventus 16G,إم إس آي RTX 4070 Ti SUPER 16 جيجا,,,"{""vram"":""16GB"",""tdp"":285}","RTX 4070 Ti Super|4070tisuper"
```

When the list is approved, import it:

```bash
uv run python -m scripts.import_curated_skus --file /path/to/skus.csv
```

Existing slugs are skipped, so the importer is safe to re-run. Aliases that
normalize to the same text are deduplicated before insert, so merchant title
variants differing only by punctuation cannot violate the alias uniqueness
constraint. The report itself needs Postgres; the importer's `--dry-run`
validation does not.

## Curation steps

1. Review the highest-count groups first; repeated titles are the safest additions.
2. Fill the CSV with canonical name, brand, model, category, price-relevant
   `specs_json`, and any known aliases. See `M3.md` for the matcher's hard gates.
3. Import the CSV. The same products can also be added one-by-one through
   `POST /api/v1/admin/products` with an admin token.
4. Let the next `scrape_all` or `recompute_offers_job` run re-evaluate staged
   listings. Manual `MATCHED`/`REJECTED` decisions are preserved.
5. Track the auto-match count before/after in `M3.md`'s verification section.

### Local verification (2026-11-28)

The broad CSV was imported into a temporary local Postgres instance and followed
by one complete `scrape_all` run:

```text
import:  created=2998  skipped=0  aliases_added=3087
scrape:  130 pages / 3,149 listings / 3,079 auto-matched (97.8%)
recompute: offers_created=2765  offers_updated=225  history_added=2971  ghosts=0
```

Per merchant, using listing counts from the run logs:

| Merchant | Auto-matched / listings | Rate |
|---|---:|---:|
| Compumarts | 1,989 / 1,992 | 99.8% |
| Nekhely | 432 / 433 | 99.8% |
| Sigma | 438 / 459 | 95.4% |
| 2B | 220 / 265 | 83.0% |

Final DB counts were 3,013 products, 3,087 aliases, 130 snapshots, 3,059 unique
staging rows (2,990 auto-matched, 69 unmatched), 2,825 offers and 3,151 history
points. The 69 unmatched rows are 19 correctly rejected bundles, 39 no-candidate
titles, 10 low-confidence suggestions and one fuzzy-title suggestion; many are
out-of-scope products found on peripheral pages (UPS units, PlayStation games,
electric scooters). Thresholds were not changed.

## Owner input still needed

The broad CSV removes the need to type every title by hand, but production still
needs an owner review pass: confirm canonical names, brands/models, categories,
`specs_json`, and AR names; drop anything not sold/tracked by the project. The
local import above was for measurement only. No AI is used to invent SKUs,
compatibility, or ranking; additions are explicit curated content, with AR/EN
phrasing handled separately as copy only.
