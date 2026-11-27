"""Import an owner-reviewed SKU CSV into the curated catalog.

This is intentionally explicit: the CSV is curated content, not an AI-generated
list. Each row becomes one canonical product, with optional AR name, specs JSON
and pipe-separated title aliases used by the deterministic matcher.

Run from ``backend/``::

    uv run python -m scripts.import_curated_skus --file /path/to/skus.csv --dry-run
    uv run python -m scripts.import_curated_skus --file /path/to/skus.csv

The dry run validates the file without touching Postgres. Existing slugs are
skipped, so the import is safe to re-run.
"""

import argparse
import asyncio
import csv
import io
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from pydantic import ValidationError
from sqlalchemy import select

from app.core.db import AsyncSessionLocal
from app.core.logging import logger
from app.models.catalog import Product, ProductAlias
from app.schemas.catalog import ProductCreate
from app.services.catalog import catalog_service
from app.services.matcher import normalize

REQUIRED_COLUMNS = ("slug", "category", "brand", "model", "name")
OPTIONAL_COLUMNS = ("name_ar", "description", "image_url", "specs_json", "aliases")
ALIAS_SEPARATORS = ("|", ";")


class SkuImportError(ValueError):
    """Raised when a CSV row cannot be turned into a curated product."""


@dataclass(frozen=True)
class CuratedSku:
    product: ProductCreate
    aliases: tuple[str, ...]


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--file", required=True, help="CSV file path, or - for stdin")
    parser.add_argument(
        "--dry-run", action="store_true", help="validate only; do not write to Postgres"
    )
    return parser.parse_args()


def parse_skus(csv_text: str) -> list[CuratedSku]:
    """Parse and validate curated SKU rows; pure function for offline checks."""
    reader = csv.DictReader(io.StringIO(csv_text))
    if reader.fieldnames is None:
        raise SkuImportError("CSV has no header row")

    missing = [column for column in REQUIRED_COLUMNS if column not in reader.fieldnames]
    if missing:
        raise SkuImportError(f"CSV is missing required columns: {', '.join(missing)}")

    skus: list[CuratedSku] = []
    for line_number, row in enumerate(reader, start=2):
        try:
            raw_specs = (row.get("specs_json") or "").strip()
            specs: dict[str, Any] = json.loads(raw_specs) if raw_specs else {}
            if not isinstance(specs, dict):
                raise SkuImportError("specs_json must contain a JSON object")

            raw_aliases = row.get("aliases") or ""
            for separator in ALIAS_SEPARATORS[1:]:
                raw_aliases = raw_aliases.replace(separator, ALIAS_SEPARATORS[0])
            aliases = tuple(
                alias.strip()
                for alias in raw_aliases.split(ALIAS_SEPARATORS[0])
                if alias.strip()
            )

            product = ProductCreate(
                slug=(row.get("slug") or "").strip(),
                category=(row.get("category") or "").strip(),
                brand=(row.get("brand") or "").strip(),
                model=(row.get("model") or "").strip(),
                name=(row.get("name") or "").strip(),
                name_ar=(row.get("name_ar") or "").strip() or None,
                description=(row.get("description") or "").strip() or None,
                image_url=(row.get("image_url") or "").strip() or None,
                specs=specs,
            )
        except (json.JSONDecodeError, ValidationError, SkuImportError) as exc:
            errors = getattr(exc, "errors", None)
            detail = errors() if callable(errors) else str(exc)
            raise SkuImportError(f"line {line_number}: {detail}") from exc
        skus.append(CuratedSku(product=product, aliases=aliases))
    return skus


def _dry_run(skus: list[CuratedSku]) -> None:
    print(json.dumps([_as_dict(sku) for sku in skus], indent=2, ensure_ascii=False))
    print(f"Validated {len(skus)} curated SKU(s); no database changes made.")


def _as_dict(sku: CuratedSku) -> dict[str, Any]:
    return {
        **sku.product.model_dump(mode="json"),
        "aliases": list(sku.aliases),
    }


async def _import(skus: list[CuratedSku]) -> None:
    created: list[str] = []
    skipped: list[str] = []
    aliases_added = 0

    async with AsyncSessionLocal() as session:
        for sku in skus:
            existing = await session.scalar(
                select(Product.id).where(Product.slug == sku.product.slug)
            )
            if existing is not None:
                skipped.append(sku.product.slug)
                continue

            product = await catalog_service.create_product(session, sku.product)
            created.append(sku.product.slug)
            for alias in sku.aliases:
                normalized = normalize(alias)
                if not normalized:
                    continue
                session.add(
                    ProductAlias(
                        product_id=product.id,
                        alias=alias[:300],
                        normalized=normalized[:300],
                        source="curated",
                    )
                )
                aliases_added += 1
        await session.commit()

    logger.info(
        "curated_skus_imported",
        created=len(created),
        skipped=len(skipped),
        aliases_added=aliases_added,
    )
    print(
        json.dumps(
            {"created": created, "skipped": skipped, "aliases_added": aliases_added},
            indent=2,
        )
    )


def main() -> None:
    args = _parse_args()
    if args.file == "-":
        csv_text = asyncio.run(_read_stdin())
    else:
        csv_text = Path(args.file).read_text(encoding="utf-8")

    try:
        skus = parse_skus(csv_text)
    except SkuImportError as exc:
        raise SystemExit(f"invalid SKU CSV: {exc}") from exc

    if not skus:
        raise SystemExit("SKU CSV contains no rows")

    if args.dry_run:
        _dry_run(skus)
    else:
        asyncio.run(_import(skus))


async def _read_stdin() -> str:
    import sys

    return sys.stdin.read()


if __name__ == "__main__":
    main()
