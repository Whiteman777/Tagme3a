"""Build a broad curated-SKU CSV from robots-allowed merchant category HTML.

This produces *candidates* for owner review. It never writes to the database and
never asks an AI model to decide compatibility or ranking: categories, specs and
aliases come from deterministic parsing of the same public pages the scrapers
already use.

Run from ``backend/``::

    uv run python -m scripts.build_curated_sku_csv --output data/curated_skus_all.csv
"""

import argparse
import asyncio
import csv
import json
import re
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

import httpx

from app.models.catalog import ProductCategory
from app.scrapers.base import slugify
from app.scrapers.registry import SCRAPERS
from app.services.matcher import (
    _BRAND_ALIASES,
    infer_category,
    normalize,
    normalized_brand,
)

URL_HINTS: tuple[tuple[str, ProductCategory], ...] = (
    ("prebuilt", ProductCategory.PREBUILT),
    ("proccesor", ProductCategory.CPU),
    ("processor", ProductCategory.CPU),
    ("graphic-card", ProductCategory.GPU),
    ("mother-board", ProductCategory.MOTHERBOARD),
    ("motherboard", ProductCategory.MOTHERBOARD),
    ("ram", ProductCategory.RAM),
    ("storage", ProductCategory.STORAGE),
    ("ssd", ProductCategory.STORAGE),
    ("hard-drives", ProductCategory.STORAGE),
    ("power-supply", ProductCategory.PSU),
    ("computer-cases", ProductCategory.CASE),
    ("cases", ProductCategory.CASE),
    ("cooler", ProductCategory.COOLER),
    ("laptop", ProductCategory.LAPTOP),
)


@dataclass(frozen=True)
class Sample:
    merchant: str
    title: str
    url: str
    brand: str = ""


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, help="destination CSV path")
    parser.add_argument(
        "--min-count",
        type=int,
        default=1,
        help="minimum repeated listings before a title becomes a candidate",
    )
    parser.add_argument(
        "--limit-per-category",
        type=int,
        default=0,
        help="maximum candidate rows per product category (0 = all)",
    )
    parser.add_argument(
        "--merchants",
        nargs="*",
        help="only these adapter keys (defaults to all registered adapters)",
    )
    return parser.parse_args()


def category_from_url(url: str) -> ProductCategory | None:
    path = urlparse(url).path.casefold()
    for hint, category in URL_HINTS:
        if hint in path:
            return category
    return None


def choose_category(samples: list[Sample]) -> ProductCategory | None:
    """Prefer the product title; use collection URLs only as a fallback/vote.

    A laptop can appear on a GPU search page and a bundle can appear on a CPU
    collection page, so the first URL hint used to misclassify those groups.
    Title votes are deterministic and more specific.
    """
    title_votes = Counter(
        inferred
        for sample in samples
        if (inferred := infer_category(sample.title)) is not None
    )
    if title_votes:
        highest = max(title_votes.values())
        winners = [category for category, count in title_votes.items() if count == highest]
        if len(winners) == 1:
            return winners[0]
        url_votes = Counter(
            hinted
            for sample in samples
            if (hinted := category_from_url(sample.url)) is not None
        )
        return max(winners, key=lambda category: (url_votes[category], title_votes[category]))

    url_votes = Counter(
        hinted
        for sample in samples
        if (hinted := category_from_url(sample.url)) is not None
    )
    return url_votes.most_common(1)[0][0] if url_votes else None


def _match(pattern: str, text: str, *, group: int = 1) -> str | None:
    found = re.search(pattern, text)
    return found.group(group) if found else None


def _form_factor(value: str) -> str | None:
    found = re.search(r"\b(mini itx|micro atx|matx|eatx|atx)\b", value)
    if not found:
        return None
    raw = found.group(1)
    return "MATX" if raw in ("micro atx", "matx") else raw.upper()


def _socket(value: str) -> str | None:
    found = re.search(r"\b(am5|am4|lga\s?(?:1700|1851))\b", value)
    return found.group(1).replace(" ", "").upper() if found else None


def specs_for(category: ProductCategory, text: str) -> dict[str, Any]:
    """Deterministically extract price-relevant specs from a merchant title."""
    value = normalize(text)
    specs: dict[str, Any] = {}

    if category is ProductCategory.CPU:
        socket = _socket(value)
        cores = _match(r"\b(\d{1,2})\s*(?:core|cores)\b", value)
        if socket:
            specs["socket"] = socket
        if cores:
            specs["cores"] = int(cores)

    elif category is ProductCategory.GPU:
        vram = _match(r"\b(\d{1,2})\s*g(?:b)?\b", value)
        tdp = _match(r"\b(\d{2,3})\s*w\b", value)
        if vram:
            specs["vram"] = f"{vram}GB"
        if tdp:
            specs["tdp"] = int(tdp)

    elif category is ProductCategory.MOTHERBOARD:
        socket = _socket(value)
        chipset = _match(r"\b(b550|b650|b760|b850|x670|x870|z690|z790|z890)\w*\b", value)
        if socket:
            specs["socket"] = socket
        if chipset:
            specs["chipset"] = chipset.upper()
        if "ddr5" in value or re.search(r"\bd5\b", value):
            specs["memory"] = "DDR5"
        elif "ddr4" in value or re.search(r"\bd4\b", value):
            specs["memory"] = "DDR4"
        form = _form_factor(value)
        if form:
            specs["form_factor"] = form

    elif category is ProductCategory.RAM:
        capacity = _match(r"\b(\d{1,3})\s*gb\b", value)
        speed = _match(r"\b(\d{4,5})\b", value)
        if capacity:
            specs["capacity_gb"] = int(capacity)
        if speed and ("ddr4" in value or "ddr5" in value):
            specs["speed"] = int(speed)
        if "ddr5" in value:
            specs["type"] = "DDR5"
        elif "ddr4" in value:
            specs["type"] = "DDR4"

    elif category is ProductCategory.PSU:
        wattage = _match(r"\b(\d{3,4})\s*w\b", value)
        efficiency = _match(r"\b(gold|bronze|platinum|silver)\b", value)
        if wattage:
            specs["wattage"] = int(wattage)
        if efficiency:
            specs["efficiency"] = efficiency.capitalize()

    elif category is ProductCategory.STORAGE:
        terabytes = _match(r"\b(\d{1,2})\s*tb\b", value)
        gigabytes = _match(r"\b(\d{3,5})\s*gb\b", value)
        if terabytes:
            specs["capacity_gb"] = int(terabytes) * 1024
        elif gigabytes:
            specs["capacity_gb"] = int(gigabytes)
        if "nvme" in value or "m 2" in value:
            specs["interface"] = "NVMe"

    elif category in (ProductCategory.LAPTOP, ProductCategory.PREBUILT):
        gpu = _match(r"\b(rtx\s?\d{3,4}\w*|rx\s?\d{3,4}\w*)\b", value)
        ram = _match(r"\b(\d{1,3})\s*gb\s*(?:ddr[45]|ram)\b", value)
        if ram is None:
            capacities = re.findall(r"\b(\d{1,3})\s*gb\b", value)
            ram = capacities[-1] if capacities else None
        if gpu:
            specs["gpu"] = gpu.upper()
        if ram:
            specs["ram"] = f"{ram}GB"

    elif category is ProductCategory.CASE:
        form = _form_factor(value)
        if form:
            specs["form_factor"] = form

    elif category is ProductCategory.COOLER:
        if "aio" in value or "liquid" in value:
            specs["type"] = "AIO"
        elif "air" in value:
            specs["type"] = "Air"

    return specs


_NON_BRANDS = frozenset({"bundle", "combo", "unknown", "generic", "oem", "na", "n a"})


def _brand_from_prefix(title: str) -> str:
    text = re.sub(r"^(?:bundle|combo)\s+", "", title.strip(), flags=re.IGNORECASE)
    for raw in sorted(_BRAND_ALIASES, key=len, reverse=True):
        if re.match(rf"^{re.escape(raw)}\b", text, flags=re.IGNORECASE):
            return normalized_brand(raw)
    first = text.split()[0] if text.split() else ""
    return normalized_brand(first)


def _clean_brand(samples: list[Sample]) -> str:
    hints = [
        normalized_brand(sample.brand)
        for sample in samples
        if sample.brand and normalized_brand(sample.brand) not in _NON_BRANDS
    ]
    if hints:
        return Counter(hints).most_common(1)[0][0]

    candidates = [_brand_from_prefix(sample.title) for sample in samples]
    candidates = [
        value
        for value in candidates
        if value and len(value) >= 2 and value not in _NON_BRANDS
    ]
    return Counter(candidates).most_common(1)[0][0] if candidates else "Unknown"


def _clean_model(brand: str, title: str) -> str:
    stripped = re.sub(rf"^{re.escape(brand)}\b", "", title, flags=re.IGNORECASE).strip()
    return (stripped or title)[:255]


def _slug(brand: str, model: str, used: set[str]) -> str:
    base = slugify(f"{brand} {model}")[:90].strip("-") or "curated-sku"
    candidate = base
    suffix = 2
    while candidate in used:
        candidate = f"{base}-{suffix}"
        suffix += 1
    used.add(candidate)
    return candidate


def build_rows(
    groups: dict[str, list[Sample]],
    *,
    min_count: int,
    limit_per_category: int,
) -> list[dict[str, Any]]:
    by_category: dict[ProductCategory, list[dict[str, Any]]] = defaultdict(list)
    used_slugs: set[str] = set()

    for normalized_title, samples in groups.items():
        if len(samples) < min_count:
            continue
        category = choose_category(samples)
        if category is None:
            continue

        brand = _clean_brand(samples)
        model = _clean_model(brand, samples[0].title)
        aliases = list(dict.fromkeys(sample.title for sample in samples))[:12]
        by_category[category].append(
            {
                "slug": _slug(brand, model, used_slugs),
                "category": category.value,
                "brand": brand,
                "model": model,
                "name": samples[0].title[:400],
                "name_ar": "",
                "description": "",
                "image_url": "",
                "specs_json": specs_for(category, " ".join(aliases)),
                "aliases": "|".join(aliases),
                "count": len(samples),
                "_normalized_title": normalized_title,
            }
        )

    rows: list[dict[str, Any]] = []
    for category in sorted(by_category, key=lambda item: item.value):
        candidates = sorted(
            by_category[category], key=lambda row: (-row["count"], row["_normalized_title"])
        )
        rows.extend(candidates[:limit_per_category] if limit_per_category > 0 else candidates)
    return rows


async def collect_samples(merchant_keys: list[str] | None) -> tuple[list[Sample], int]:
    keys = merchant_keys or sorted(SCRAPERS)
    samples: list[Sample] = []
    pages = 0
    async with httpx.AsyncClient(timeout=20.0, follow_redirects=True) as client:
        for key in keys:
            scraper_class = SCRAPERS[key.casefold()]
            scraper = scraper_class(delay=1.0, timeout=20.0, max_retries=1)
            seen_pages: set[str] = set()
            for seed in scraper.listing_urls():
                queue = [seed]
                while queue:
                    url = queue.pop(0)
                    if url in seen_pages:
                        continue
                    seen_pages.add(url)
                    try:
                        fetched = await scraper.fetch(url, client)
                    except Exception as exc:  # noqa: BLE001 - one page must not stop curation
                        print(f"skip {url}: {exc}", file=sys.stderr)
                        continue
                    pages += 1
                    listings = scraper.parse(fetched.html, url=fetched.url)
                    samples.extend(
                        Sample(key, listing.title, listing.url, listing.brand or "")
                        for listing in listings
                    )
                    queue.extend(scraper.additional_pages(fetched.html, url=fetched.url))
            print(f"{key}: {len(seen_pages)} pages", file=sys.stderr)
    return samples, pages


async def _async_main(args: argparse.Namespace) -> None:
    samples, pages = await collect_samples(args.merchants)
    groups: dict[str, list[Sample]] = defaultdict(list)
    for sample in samples:
        groups[normalize(sample.title)].append(sample)

    rows = build_rows(
        groups,
        min_count=args.min_count,
        limit_per_category=args.limit_per_category,
    )
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    fieldnames = [
        "slug", "category", "brand", "model", "name", "name_ar",
        "description", "image_url", "specs_json", "aliases",
    ]
    with output.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        for row in rows:
            writer.writerow({**row, "specs_json": json.dumps(row["specs_json"])})

    counts = Counter(row["category"] for row in rows)
    print(
        f"pages={pages} listings={len(samples)} groups={len(groups)} "
        f"rows={len(rows)} output={output}",
        file=sys.stderr,
    )
    summary = ", ".join(f"{key}={value}" for key, value in sorted(counts.items()))
    print(f"category counts: {summary}", file=sys.stderr)


def main() -> None:
    asyncio.run(_async_main(_parse_args()))


if __name__ == "__main__":
    main()
