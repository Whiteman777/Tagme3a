"""Turn staged merchant listings into a SKU-curation shortlist.

The matcher can only auto-match products that exist in the catalog. This report
groups unmatched/manually matched staging rows by merchant + normalized title so
an owner can decide which missing SKUs to add before raising match coverage.

Run from ``backend/``::

    uv run python -m scripts.sku_curation_report --format markdown --limit 40
    uv run python -m scripts.sku_curation_report --format json > /tmp/sku-report.json
"""

import argparse
import asyncio
import json
from collections import Counter
from collections.abc import Iterable
from datetime import UTC, datetime
from decimal import Decimal
from typing import Any

from sqlalchemy import select

from app.core.db import AsyncSessionLocal
from app.models.catalog import Merchant
from app.models.scraping import MatchStatus, StagingListing

DEFAULT_STATUSES = (MatchStatus.UNMATCHED, MatchStatus.MATCHED)


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--status",
        action="append",
        choices=[status.value for status in MatchStatus],
        help="repeatable; defaults to unmatched and matched",
    )
    parser.add_argument("--format", choices=("markdown", "json"), default="markdown")
    parser.add_argument("--limit", type=int, default=50, help="maximum candidate groups")
    parser.add_argument("--min-count", type=int, default=1)
    parser.add_argument("--merchant", help="only this merchant key")
    return parser.parse_args()


def build_report(
    rows: Iterable[tuple[StagingListing, str]],
    *,
    statuses: Iterable[MatchStatus],
    limit: int,
    min_count: int,
    merchant_filter: str | None = None,
) -> dict[str, Any]:
    """Group raw staging rows into candidate SKUs; no database dependency."""
    status_values = [status.value for status in statuses]
    groups: dict[tuple[str, str], dict[str, Any]] = {}
    totals: Counter[str] = Counter()

    for row, merchant_key in rows:
        if merchant_filter and merchant_key != merchant_filter:
            continue
        status = row.match_status.value if hasattr(row.match_status, "value") else row.match_status
        if status not in status_values:
            continue
        totals[f"{merchant_key}:{status}"] += 1

        title = (row.normalized_name or row.raw_title).strip().casefold()
        key = (merchant_key, title)
        price = Decimal(str(row.price_egp))
        group = groups.setdefault(
            key,
            {
                "merchant_key": merchant_key,
                "candidate_title": (row.normalized_name or row.raw_title).strip(),
                "sample_raw_title": row.raw_title,
                "brand": row.brand,
                "model": row.model,
                "category": row.category.value if hasattr(row.category, "value") else row.category,
                "count": 0,
                "min_price_egp": price,
                "max_price_egp": price,
                "suggested_product_id": row.suggested_product_id,
                "suggestion_confidence": (
                    str(row.suggestion_confidence)
                    if row.suggestion_confidence is not None
                    else None
                ),
                "sample_url": row.url,
                "statuses": set(),
            },
        )
        group["count"] += 1
        group["min_price_egp"] = min(group["min_price_egp"], price)
        group["max_price_egp"] = max(group["max_price_egp"], price)
        group["statuses"].add(status)

    candidates = [group for group in groups.values() if group["count"] >= min_count]
    candidates.sort(
        key=lambda group: (-group["count"], group["merchant_key"], group["candidate_title"])
    )
    for group in candidates:
        group["statuses"] = sorted(group["statuses"])
        group["min_price_egp"] = str(group["min_price_egp"])
        group["max_price_egp"] = str(group["max_price_egp"])

    return {
        "generated_at": datetime.now(UTC).isoformat(),
        "filters": {
            "statuses": status_values,
            "merchant": merchant_filter,
            "min_count": min_count,
            "limit": limit,
        },
        "totals": dict(sorted(totals.items())),
        "candidate_count": len(candidates),
        "candidates": candidates[:limit],
    }


def render_markdown(report: dict[str, Any]) -> str:
    lines = [
        "# SKU curation candidates",
        "",
        f"Generated: {report['generated_at']}",
        f"Statuses: {', '.join(report['filters']['statuses'])}",
        f"Candidate groups: {report['candidate_count']} (showing {len(report['candidates'])})",
        "",
        "Add these SKUs to the curated catalog before changing matcher thresholds.",
        "",
        "| Merchant | Candidate | Brand | Model | Count | EGP range | Suggested | URL |",
        "|---|---|---|---|---:|---|---:|---|",
    ]
    for group in report["candidates"]:
        lines.append(
            "| {merchant_key} | {candidate_title} | {brand} | {model} | {count} | "
            "{min_price_egp}–{max_price_egp} | {suggested_product_id} | {sample_url} |".format(
                merchant_key=group["merchant_key"],
                candidate_title=group["candidate_title"].replace("|", "\\|"),
                brand=group["brand"] or "",
                model=(group["model"] or "").replace("|", "\\|"),
                count=group["count"],
                min_price_egp=group["min_price_egp"],
                max_price_egp=group["max_price_egp"],
                suggested_product_id=group["suggested_product_id"] or "",
                sample_url=group["sample_url"],
            )
        )
    if report["totals"]:
        lines.extend(["", "## Staging totals", ""])
        lines.extend(f"- `{key}`: {value}" for key, value in report["totals"].items())
    return "\n".join(lines) + "\n"


async def _load_rows(
    statuses: list[MatchStatus], merchant: str | None
) -> list[tuple[StagingListing, str]]:
    async with AsyncSessionLocal() as session:
        stmt = (
            select(StagingListing, Merchant.key)
            .join(Merchant, Merchant.id == StagingListing.merchant_id)
            .where(StagingListing.match_status.in_(statuses))
        )
        if merchant:
            stmt = stmt.where(Merchant.key == merchant)
        result = await session.execute(stmt.order_by(Merchant.key, StagingListing.id))
        return [(row, key) for row, key in result.all()]


def main() -> None:
    args = _parse_args()
    statuses = (
        [MatchStatus(value) for value in args.status]
        if args.status
        else list(DEFAULT_STATUSES)
    )
    rows = asyncio.run(_load_rows(statuses, args.merchant))
    report = build_report(
        rows,
        statuses=statuses,
        limit=args.limit,
        min_count=args.min_count,
        merchant_filter=args.merchant,
    )
    if args.format == "json":
        print(json.dumps(report, indent=2, ensure_ascii=False))
    else:
        print(render_markdown(report), end="")


if __name__ == "__main__":
    main()
