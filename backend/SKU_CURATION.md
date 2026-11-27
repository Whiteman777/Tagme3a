# SKU curation workflow

Status: **report + CSV importer ready; target SKU list required from the owner**.

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
  `cooler`, `storage`, `laptop`, `peripheral`.
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

Existing slugs are skipped, so the importer is safe to re-run. The report itself
needs Postgres; the importer's `--dry-run` validation does not.

## Curation steps

1. Review the highest-count groups first; repeated titles are the safest additions.
2. Fill the CSV with canonical name, brand, model, category, price-relevant
   `specs_json`, and any known aliases. See `M3.md` for the matcher's hard gates.
3. Import the CSV. The same products can also be added one-by-one through
   `POST /api/v1/admin/products` with an admin token.
4. Let the next `scrape_all` or `recompute_offers_job` run re-evaluate staged
   listings. Manual `MATCHED`/`REJECTED` decisions are preserved.
5. Track the auto-match count before/after in `M3.md`'s verification section.

## Owner input still needed

Provide the target SKU shortlist (canonical names + brands/models + expected
categories) for the Egyptian market. Once supplied, products can be added and the
raw match rate measured again. No AI is used to invent SKUs, compatibility, or
ranking; additions are explicit curated content, with AR/EN phrasing handled
separately as copy only.
