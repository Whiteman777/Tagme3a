"""M1 auth tests (Firebase token verification is dependency-overridden)."""
from httpx import AsyncClient

from app.models.user import UserRole


async def test_me_creates_user_on_first_call(client: AsyncClient) -> None:
    response = await client.get("/api/v1/auth/me")
    assert response.status_code == 200
    body = response.json()
    assert body["email"] == "tester@example.com"
    assert body["role"] == UserRole.USER.value
    assert body["id"] > 0


async def test_auth_sync_enriches_missing_fields(client: AsyncClient) -> None:
    first = await client.get("/api/v1/auth/me")
    assert first.status_code == 200

    response = await client.post(
        "/api/v1/auth/sync",
        json={"display_name": "Test User", "phone": "+201234567890"},
    )
    assert response.status_code == 200
    assert response.json()["display_name"] == "Test User"
    assert response.json()["phone"] == "+201234567890"
