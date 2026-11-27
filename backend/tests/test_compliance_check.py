"""Robots checks use each adapter's own identifying user agent."""

import httpx

from app.scrapers.compumarts import CompumartsScraper
from scripts.check_merchant_compliance import check_adapter

SEED = "https://www.compumarts.com/collections/pc-parts-proccesor?page=1"


async def test_robots_check_reports_allowed_and_disallowed_urls() -> None:
    captured: list[str] = []

    def handler(request: httpx.Request) -> httpx.Response:
        captured.append(request.headers.get("user-agent", ""))
        if request.url.path == "/robots.txt":
            return httpx.Response(
                200,
                text="User-agent: *\nAllow: /collections\nDisallow: /cart\n",
            )
        return httpx.Response(200, text="ok")

    async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
        report = await check_adapter(
            CompumartsScraper,
            client,
            [SEED, "https://www.compumarts.com/cart"],
        )

    assert report["adapter"] == "compumarts"
    assert report["user_agents"] == [
        "Tagme3aPriceBot/1.0 (+https://github.com/Whiteman777/Tagme3a)"
    ]
    assert [item["robots_allowed"] for item in report["urls"]] == [True, False]
    assert all(ua.split("/")[0] == "Tagme3aPriceBot" for ua in captured)
