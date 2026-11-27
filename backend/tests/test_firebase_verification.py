"""Unit coverage for the real Firebase verification code path."""

import argparse
from types import SimpleNamespace
from typing import Any

import firebase_admin.auth
import httpx
import pytest
from fastapi import HTTPException
from fastapi.security import HTTPAuthorizationCredentials

from app.core import security
from app.core.config import settings
from scripts import verify_firebase_auth as verify_script


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


def test_emulator_script_initializes_app_before_creating_user(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    calls: list[str] = []
    created_email: dict[str, str] = {}
    monkeypatch.delenv("FIREBASE_AUTH_EMULATOR_HOST", raising=False)
    monkeypatch.setattr(settings, "FIREBASE_PROJECT_ID", "demo-tagme3a")
    monkeypatch.setattr(verify_script, "_get_firebase_app", lambda: calls.append("init"))
    def fake_create_user(**kwargs: Any) -> SimpleNamespace:
        calls.append("create")
        created_email["value"] = kwargs["email"]
        return SimpleNamespace(uid="uid-1")

    monkeypatch.setattr(firebase_admin.auth, "create_user", fake_create_user)
    monkeypatch.setattr(
        firebase_admin.auth,
        "delete_user",
        lambda uid: calls.append("delete"),
    )
    monkeypatch.setattr(
        verify_script.httpx,
        "post",
        lambda *args, **kwargs: httpx.Response(
            200,
            json={"idToken": "emulator-token"},
            request=httpx.Request("POST", "http://emulator.test/token"),
        ),
    )
    monkeypatch.setattr(
        verify_script,
        "_decode",
        lambda token: {"uid": "uid-1", "email": created_email["value"]},
    )

    verify_script._verify_with_emulator(
        argparse.Namespace(emulator_host="127.0.0.1:9099", expected_uid=None)
    )

    assert calls == ["init", "create", "delete"]


def test_live_test_user_mode_verifies_and_cleans_up(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    calls: list[str] = []
    created_email: dict[str, str] = {}
    monkeypatch.setenv("FIREBASE_WEB_API_KEY", "web-key")
    monkeypatch.delenv("FIREBASE_AUTH_EMULATOR_HOST", raising=False)
    monkeypatch.setattr(settings, "FIREBASE_PROJECT_ID", "tagme3a")
    monkeypatch.setattr(verify_script, "_get_firebase_app", lambda: calls.append("init"))

    def fake_create_user(**kwargs: Any) -> SimpleNamespace:
        calls.append("create")
        created_email["value"] = kwargs["email"]
        return SimpleNamespace(uid="uid-1")

    def fake_post(url: str, **kwargs: Any) -> httpx.Response:
        calls.append("signin")
        assert kwargs["params"] == {"key": "web-key"}
        return httpx.Response(
            200,
            json={"idToken": "live-token"},
            request=httpx.Request("POST", url),
        )

    monkeypatch.setattr(firebase_admin.auth, "create_user", fake_create_user)
    monkeypatch.setattr(
        firebase_admin.auth,
        "delete_user",
        lambda uid: calls.append("delete"),
    )
    monkeypatch.setattr(verify_script.httpx, "post", fake_post)
    monkeypatch.setattr(
        verify_script,
        "_decode",
        lambda token: {"uid": "uid-1", "email": created_email["value"]},
    )

    verify_script._verify_with_test_user(argparse.Namespace(expected_uid=None))

    assert calls == ["init", "create", "signin", "delete"]


def test_live_test_user_mode_requires_web_api_key(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.delenv("FIREBASE_WEB_API_KEY", raising=False)
    monkeypatch.delenv("WEB_API_KEY", raising=False)

    with pytest.raises(SystemExit, match="FIREBASE_WEB_API_KEY"):
        verify_script._verify_with_test_user(argparse.Namespace(expected_uid=None))
