"""SKU curation report groups unmatched listings without needing a database."""

from decimal import Decimal
from types import SimpleNamespace

from app.models.scraping import MatchStatus
from scripts.sku_curation_report import build_report, render_markdown


def _listing(**overrides: object) -> SimpleNamespace:
    defaults: dict[str, object] = {
        "raw_title": "Gaming Laptop RTX 4060",
        "normalized_name": "Gaming Laptop RTX 4060",
        "brand": "Lenovo",
        "model": "LOQ",
        "category": None,
        "price_egp": Decimal("45000.00"),
        "url": "https://merchant.example/p/1",
        "match_status": MatchStatus.UNMATCHED,
        "suggested_product_id": None,
        "suggestion_confidence": None,
    }
    defaults.update(overrides)
    return SimpleNamespace(**defaults)


def test_groups_repeated_titles_and_tracks_price_range() -> None:
    rows = [
        (_listing(price_egp=Decimal("45000.00")), "compumarts"),
        (
            _listing(
                normalized_name="gaming laptop rtx 4060",
                price_egp=Decimal("43000.50"),
                url="https://merchant.example/p/2",
            ),
            "compumarts",
        ),
        (_listing(raw_title="Different Item", normalized_name="Different Item"), "sigma"),
    ]

    report = build_report(
        rows,
        statuses=(MatchStatus.UNMATCHED, MatchStatus.MATCHED),
        limit=10,
        min_count=1,
    )

    assert report["candidate_count"] == 2
    assert report["totals"] == {"compumarts:unmatched": 2, "sigma:unmatched": 1}
    candidate = report["candidates"][0]
    assert candidate["merchant_key"] == "compumarts"
    assert candidate["count"] == 2
    assert candidate["min_price_egp"] == "43000.50"
    assert candidate["max_price_egp"] == "45000.00"
    assert candidate["statuses"] == ["unmatched"]


def test_filters_rejected_rows_and_respects_limits() -> None:
    rows = [
        (_listing(), "compumarts"),
        (_listing(match_status=MatchStatus.REJECTED), "compumarts"),
        (_listing(raw_title="Other", normalized_name="Other"), "sigma"),
    ]

    report = build_report(
        rows,
        statuses=(MatchStatus.UNMATCHED, MatchStatus.MATCHED),
        limit=1,
        min_count=1,
    )

    assert report["totals"] == {"compumarts:unmatched": 1, "sigma:unmatched": 1}
    assert len(report["candidates"]) == 1
    assert "Gaming Laptop RTX 4060" in render_markdown(report)
