"""Tests for the owner-reviewed curated SKU CSV importer."""

import csv
import io

import pytest

from scripts.import_curated_skus import (
    OPTIONAL_COLUMNS,
    REQUIRED_COLUMNS,
    SkuImportError,
    parse_skus,
)


def _csv(rows: list[list[str]], header: list[str] | None = None) -> str:
    buffer = io.StringIO()
    writer = csv.writer(buffer)
    writer.writerow(header or list(REQUIRED_COLUMNS) + list(OPTIONAL_COLUMNS))
    for row in rows:
        writer.writerow(row)
    return buffer.getvalue()


def test_parses_specs_and_aliases() -> None:
    text = _csv(
        [
            [
                "ddr5-32g-6400",
                "ram",
                "Corsair",
                "Vengeance 32GB 6400",
                "Corsair Vengeance 32GB DDR5 6400",
                "كورسير 32 جيجا 6400",
                "",
                "",
                '{"capacity_gb": 32, "speed": 6400}',
                "vengeance 32gb 6400|Corsair 32G 6400",
            ]
        ]
    )

    skus = parse_skus(text)

    assert len(skus) == 1
    sku = skus[0]
    assert sku.product.slug == "ddr5-32g-6400"
    assert sku.product.category.value == "ram"
    assert sku.product.specs == {"capacity_gb": 32, "speed": 6400}
    assert sku.aliases == ("vengeance 32gb 6400", "Corsair 32G 6400")


def test_rejects_missing_required_column() -> None:
    text = _csv([], header=["slug", "brand", "model"])

    with pytest.raises(SkuImportError, match="missing required columns"):
        parse_skus(text)


def test_rejects_invalid_specs_json() -> None:
    text = _csv(
        [
            [
                "bad-specs",
                "cpu",
                "AMD",
                "Example",
                "Example CPU",
                "",
                "",
                "",
                "{not-json",
                "",
            ]
        ]
    )

    with pytest.raises(SkuImportError, match="line 2"):
        parse_skus(text)
