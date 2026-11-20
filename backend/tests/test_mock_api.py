"""Standalone mock API tests — no DB, Firebase, Redis or Meilisearch involved."""

from collections.abc import AsyncGenerator
from decimal import Decimal

import pytest
from httpx import ASGITransport, AsyncClient

from app.mock_main import create_app

USER_TOKEN = "mock-user-token"
ADMIN_TOKEN = "mock-admin-token"


def auth(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
async def client() -> AsyncGenerator[AsyncClient, None]:
    transport = ASGITransport(app=create_app())
    async with AsyncClient(transport=transport, base_url="http://mock") as http_client:
        yield http_client


async def test_health_and_ready(client: AsyncClient) -> None:
    health = await client.get("/health")
    assert health.status_code == 200
    assert health.json()["status"] == "ok"
    assert health.json()["service"] == "tagme3a-mock-api"
    assert health.json()["mock"] is True

    ready = await client.get("/ready")
    assert ready.status_code == 200
    assert ready.json() == {"status": "ready", "mode": "in-memory"}


async def test_no_dependency_overrides_needed() -> None:
    """The mock app must be usable without the real app's DB/Firebase overrides."""
    app = create_app()
    assert app.dependency_overrides == {}
    assert app.state.mock.products


async def test_auth_requires_token_and_sync_updates_profile(client: AsyncClient) -> None:
    missing = await client.get("/api/v1/auth/me")
    assert missing.status_code == 401

    me = await client.get("/api/v1/auth/me", headers=auth(USER_TOKEN))
    assert me.status_code == 200
    assert me.json()["role"] == "user"

    synced = await client.post(
        "/api/v1/auth/sync",
        headers=auth(USER_TOKEN),
        json={"email": "tester@example.com", "display_name": "Test User"},
    )
    assert synced.status_code == 200, synced.text
    assert synced.json()["display_name"] == "Test User"
    assert synced.json()["email"] == "tester@example.com"

    me_again = await client.get("/api/v1/auth/me", headers=auth(USER_TOKEN))
    assert me_again.json()["display_name"] == "Test User"


async def test_list_search_and_filters(client: AsyncClient) -> None:
    page = await client.get("/api/v1/products")
    assert page.status_code == 200
    body = page.json()
    assert body["total"] == 15
    assert body["search_backend"] == "memory"
    assert body["items"][0]["lowest_price_egp"] is not None

    arabic = await client.get("/api/v1/products", params={"q": "جيجابايت"})
    assert arabic.status_code == 200
    assert arabic.json()["total"] >= 1

    filtered = await client.get("/api/v1/products", params={"category": "gpu", "merchant": "sigma"})
    assert filtered.status_code == 200
    assert filtered.json()["total"] == 3
    assert all(item["category"] == "gpu" for item in filtered.json()["items"])

    descending = await client.get("/api/v1/products", params={"sort": "price_desc"})
    prices = [Decimal(item["lowest_price_egp"]) for item in descending.json()["items"]]
    assert prices == sorted(prices, reverse=True)

    paged = await client.get("/api/v1/products", params={"page": 2, "page_size": 5})
    assert paged.json()["total"] == 15
    assert len(paged.json()["items"]) == 5
    assert paged.json()["page"] == 2


async def test_detail_ranks_eligible_offers_and_includes_history(client: AsyncClient) -> None:
    response = await client.get("/api/v1/products/rtx-4060-windforce")
    assert response.status_code == 200
    body = response.json()

    assert body["best_offer"]["merchant"]["key"] == "sigma"
    assert body["best_offer"]["reason"] == "lowest_price_in_stock"
    assert body["best_offer"]["sponsored"] is False

    in_stock_prices = [Decimal(o["price_egp"]) for o in body["offers"] if o["in_stock"]]
    assert in_stock_prices == sorted(in_stock_prices)
    assert body["offers"][-1]["merchant"]["key"] == "amazon_eg"  # out of stock -> ineligible
    assert body["merchant_count"] == 3
    assert len(body["price_history"]) == 12


async def test_merchants_and_price_history_endpoints(client: AsyncClient) -> None:
    merchants = await client.get("/api/v1/products/merchants")
    assert merchants.status_code == 200
    assert [m["key"] for m in merchants.json()] == ["sigma", "compumarts", "nekhely", "amazon_eg"]

    history = await client.get("/api/v1/products/1/price-history", params={"limit": 5})
    assert history.status_code == 200
    assert len(history.json()) == 5

    unknown = await client.get("/api/v1/products/9999/price-history")
    assert unknown.status_code == 200
    assert unknown.json() == []

    not_found = await client.get("/api/v1/products/does-not-exist")
    assert not_found.status_code == 404


async def test_admin_role_behavior(client: AsyncClient) -> None:
    payload = {
        "slug": "test-part",
        "category": "cpu",
        "brand": "Test",
        "model": "X1",
        "name": "Test Part",
    }

    forbidden = await client.post("/api/v1/admin/products", headers=auth(USER_TOKEN), json=payload)
    assert forbidden.status_code == 403

    created = await client.post("/api/v1/admin/products", headers=auth(ADMIN_TOKEN), json=payload)
    assert created.status_code == 201, created.text
    product_id = created.json()["id"]
    assert created.json()["best_offer"] is None

    duplicate = await client.post("/api/v1/admin/products", headers=auth(ADMIN_TOKEN), json=payload)
    assert duplicate.status_code == 409

    updated = await client.patch(
        f"/api/v1/admin/products/{product_id}",
        headers=auth(ADMIN_TOKEN),
        json={"name": "Updated Part"},
    )
    assert updated.status_code == 200, updated.text
    assert updated.json()["name"] == "Updated Part"

    deleted = await client.delete(f"/api/v1/admin/products/{product_id}", headers=auth(ADMIN_TOKEN))
    assert deleted.status_code == 204

    gone = await client.get("/api/v1/products/test-part")
    assert gone.status_code == 404
