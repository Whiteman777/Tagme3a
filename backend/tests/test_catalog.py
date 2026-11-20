"""M1 catalog tests: seed, search, detail, best-offer ranking, filters, admin RBAC."""
from httpx import AsyncClient
from sqlalchemy import select

from app.core.db import AsyncSession
from app.models.user import User, UserRole


async def test_seed_and_list(client: AsyncClient, seeded: None) -> None:
    response = await client.get("/api/v1/products")
    assert response.status_code == 200
    body = response.json()
    assert body["total"] >= 15
    assert len(body["items"]) > 0
    assert body["items"][0]["lowest_price_egp"] is not None


async def test_search_arabic(client: AsyncClient, seeded: None) -> None:
    response = await client.get("/api/v1/products", params={"q": "جيجابايت"})
    assert response.status_code == 200
    assert response.json()["total"] >= 1


async def test_filter_by_category_and_merchant(client: AsyncClient, seeded: None) -> None:
    response = await client.get(
        "/api/v1/products", params={"category": "gpu", "merchant": "sigma"}
    )
    assert response.status_code == 200
    body = response.json()
    assert body["total"] >= 3
    assert all(item["category"] == "gpu" for item in body["items"])


async def test_detail_has_ranked_offers_and_history(client: AsyncClient, seeded: None) -> None:
    response = await client.get("/api/v1/products/rtx-4060-windforce")
    assert response.status_code == 200
    body = response.json()
    assert body["best_offer"] is not None
    assert body["best_offer"]["merchant"]["key"] == "sigma"
    assert body["best_offer"]["reason"] == "lowest_price_in_stock"
    prices = [o["price_egp"] for o in body["offers"] if o["in_stock"]]
    assert prices == sorted(prices)
    assert len(body["price_history"]) > 0


async def test_price_history_endpoint(client: AsyncClient, seeded: None) -> None:
    response = await client.get("/api/v1/products/1/price-history")
    assert response.status_code == 200
    assert isinstance(response.json(), list)


async def test_admin_requires_admin_role(client: AsyncClient, db: AsyncSession) -> None:
    response = await client.post(
        "/api/v1/admin/products",
        json={
            "slug": "test-part", "category": "cpu", "brand": "Test", "model": "X1",
            "name": "Test Part",
        },
    )
    assert response.status_code == 403


async def test_admin_can_create_and_delete(
    client: AsyncClient, db: AsyncSession, auth_uid: str
) -> None:
    user = await db.scalar(select(User).where(User.firebase_uid == auth_uid))
    if user is None:
        user = User(firebase_uid=auth_uid, email="admin@example.com", role=UserRole.ADMIN)
        db.add(user)
    else:
        user.role = UserRole.ADMIN
    await db.commit()

    created = await client.post(
        "/api/v1/admin/products",
        json={
            "slug": "test-part", "category": "cpu", "brand": "Test", "model": "X1",
            "name": "Test Part",
        },
    )
    assert created.status_code == 201, created.text
    product_id = created.json()["id"]

    deleted = await client.delete(f"/api/v1/admin/products/{product_id}")
    assert deleted.status_code == 204
