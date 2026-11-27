"""Re-check robots.txt and agent identity for every registered merchant adapter.

This is a review aid, not legal approval. Run it before each crawl-policy change
and attach the output to the owner/legal sign-off recorded in ``COMPLIANCE.md``.

Run from ``backend/``::

    uv run python -m scripts.check_merchant_compliance --format markdown
    uv run python -m scripts.check_merchant_compliance --url https://shop.example/product/1
"""

import argparse
import asyncio
import json
from typing import Any

import httpx

from app.scrapers.base import BaseScraper
from app.scrapers.registry import SCRAPERS


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--format", choices=("markdown", "json"), default="markdown")
    parser.add_argument(
        "--url",
        action="append",
        help="check this URL instead of the adapter's seed URLs; repeatable",
    )
    parser.add_argument("--adapter", help="only check this adapter key")
    parser.add_argument("--timeout", type=float, default=10.0)
    return parser.parse_args()


async def check_adapter(
    scraper_type: type[BaseScraper], client: httpx.AsyncClient, urls: list[str] | None = None
) -> dict[str, Any]:
    """Evaluate robots.txt for an adapter using its own identifying UA."""
    result: dict[str, Any] = {
        "adapter": scraper_type.key,
        "user_agents": list(scraper_type.user_agents),
        "max_pages": scraper_type.max_pages,
        "web_bot_auth_required": scraper_type.web_bot_auth,
        "web_bot_auth_enabled": False,
        "urls": [],
    }
    try:
        scraper = scraper_type(delay=0, timeout=10.0, max_retries=0, client=client)
    except ValueError as exc:
        result["error"] = str(exc)
        return result

    result["web_bot_auth_enabled"] = scraper._web_auth is not None
    targets = urls or scraper.listing_urls()
    for url in targets:
        try:
            allowed = await scraper._robots_allowed(url, client)
            result["urls"].append({"url": url, "robots_allowed": allowed})
        except Exception as exc:  # noqa: BLE001 - report per-URL, keep auditing
            result["urls"].append({"url": url, "robots_allowed": False, "error": str(exc)})
    return result


def render_markdown(reports: list[dict[str, Any]]) -> str:
    lines = [
        "# Merchant robots / agent identity check",
        "",
        "Machine-checked only. Legal and commercial approval still require owner sign-off.",
        "",
        "| Adapter | Identifying UA | WBA | Max pages | URL | Robots allows | Notes |",
        "|---|---|---|---:|---|---|---|",
    ]
    for report in reports:
        ua = report["user_agents"][0] if report["user_agents"] else "(default browser UA)"
        if report["web_bot_auth_enabled"]:
            wba = "enabled"
        elif report["web_bot_auth_required"]:
            wba = "required"
        else:
            wba = "n/a"
        if report.get("error"):
            lines.append(
                f"| {report['adapter']} | {ua} | {wba} | {report['max_pages']} | - | no | "
                f"{report['error']} |"
            )
        for item in report["urls"]:
            lines.append(
                f"| {report['adapter']} | {ua} | {wba} | {report['max_pages']} | "
                f"{item['url']} | {'yes' if item['robots_allowed'] else 'no'} | "
                f"{item.get('error', '')} |"
            )
    return "\n".join(lines) + "\n"


async def _run(args: argparse.Namespace) -> list[dict[str, Any]]:
    keys = [args.adapter] if args.adapter else sorted(SCRAPERS)
    unknown = [key for key in keys if key not in SCRAPERS]
    if unknown:
        raise SystemExit(f"unknown adapter(s): {', '.join(unknown)}")

    async with httpx.AsyncClient(timeout=args.timeout, follow_redirects=True) as client:
        return [
            await check_adapter(SCRAPERS[key], client, args.url or None) for key in keys
        ]


def main() -> None:
    args = _parse_args()
    reports = asyncio.run(_run(args))
    if args.format == "json":
        print(json.dumps(reports, indent=2, ensure_ascii=False))
    else:
        print(render_markdown(reports), end="")


if __name__ == "__main__":
    main()
