"""Unit coverage for the real Firebase verification code path."""

from typing import Any

import pytest
from fastapi import HTTPException
from fastapi.security import HTTPAuthorizationCredentials

from app.core import security


@pytest.fixture(autouse=True)
def _reset_firebase_app(monkeypatch: pytest.MonkeyPatch) -> None:
    """Never let these tests leave a cached Firebase app behind."""
    monkeypatch.setattr(security, "_firebase_app", None)


async def test_decode_token_requires_credentials() -> None:
    with pytest.raises(HTTPException) as exc:
        await security.decode_token(None)  # type: ignore[arg-type]

    assert exc.value.status_code == 401


async def test_decode_token_verifies_with_firebase(monkeypatch: pytest.MonkeyPatch) -> None:
    sentinel = object()
    captured: dict[str, Any] = {}
    monkeypatch.setattr(security, "_get_firebase_app", lambda: sentinel)

    def fake_verify(token: str, *, app: object, check_revoked: bool) -> dict[str, Any]:
        captured.update(token=token, app=app, check_revoked=check_revoked)
        return {"uid": "firebase-uid", "email": "user@example.com"}

    monkeypatch.setattr(security.firebase_auth, "verify_id_token", fake_verify)
    bearer = HTTPAuthorizationCredentials(scheme="Bearer", credentials="real-id-token")

    claims = await security.decode_token(bearer)

    assert claims["uid"] == "firebase-uid"
    assert captured == {"token": "real-id-token", "app": sentinel, "check_revoked": False}


async def test_decode_token_rejects_invalid_token(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(security, "_get_firebase_app", lambda: object())

    def fake_verify(*args: Any, **kwargs: Any) -> None:
        raise ValueError("invalid token")

    monkeypatch.setattr(security.firebase_auth, "verify_id_token", fake_verify)
    bearer = HTTPAuthorizationCredentials(scheme="Bearer", credentials="bad-token")

    with pytest.raises(HTTPException) as exc:
        await security.decode_token(bearer)

    assert exc.value.status_code == 401
    assert exc.value.headers == {"WWW-Authenticate": "Bearer"}


def test_emulator_init_skips_service_account(monkeypatch: pytest.MonkeyPatch) -> None:
    sentinel = object()
    captured: dict[str, Any] = {}
    monkeypatch.setenv("FIREBASE_AUTH_EMULATOR_HOST", "127.0.0.1:9099")
    monkeypatch.setattr(security.settings, "FIREBASE_PROJECT_ID", "demo-tagme3a")
    monkeypatch.setattr(security.firebase_admin, "_apps", {})

    def fake_initialize_app(credential: object | None, options: dict[str, str]) -> object:
        captured.update(credential=credential, options=options)
        return sentinel

    monkeypatch.setattr(security.firebase_admin, "initialize_app", fake_initialize_app)

    assert security._get_firebase_app() is sentinel
    assert captured == {"credential": None, "options": {"projectId": "demo-tagme3a"}}
