"""Verify a real Firebase ID token through the backend's ``decode_token``.

Three modes:

1. ``--token`` (or ``FIREBASE_ID_TOKEN``) checks a token obtained from a signed-in
   client, against a real Firebase project.
2. ``--emulator-host HOST`` creates a temporary user in the Auth emulator, signs in
   through the emulator REST API, and verifies that token with the same code path.
3. ``--create-test-user`` creates a temporary user in the *live* project, signs it
   in through the Firebase REST API, verifies the token, then deletes the user.
   Requires ``FIREBASE_WEB_API_KEY`` and the service account configured in
   ``FIREBASE_CREDENTIALS``.

Run from ``backend/``::

    uv run python -m scripts.verify_firebase_auth --token "$FIREBASE_ID_TOKEN"
    FIREBASE_PROJECT_ID=demo-tagme3a uv run python -m scripts.verify_firebase_auth \
      --emulator-host 127.0.0.1:9099
    FIREBASE_PROJECT_ID=tagme3a FIREBASE_WEB_API_KEY=... \
      uv run python -m scripts.verify_firebase_auth --create-test-user
"""

import argparse
import asyncio
import json
import os
import secrets
from typing import Any

import httpx
from fastapi.security import HTTPAuthorizationCredentials

from app.core.config import settings
from app.core.security import _get_firebase_app, decode_token


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--token", help="Firebase ID token; defaults to FIREBASE_ID_TOKEN")
    parser.add_argument(
        "--emulator-host",
        help="FIREBASE_AUTH_EMULATOR_HOST (for example 127.0.0.1:9099)",
    )
    parser.add_argument(
        "--create-test-user",
        action="store_true",
        help="create, verify and delete a temporary user in the live Firebase project",
    )
    parser.add_argument("--expected-uid", help="Fail unless the decoded token has this uid")
    return parser.parse_args()


def _decode(token: str) -> dict[str, Any]:
    bearer = HTTPAuthorizationCredentials(scheme="Bearer", credentials=token)
    return asyncio.run(decode_token(bearer))


def _print_claims(claims: dict[str, Any]) -> None:
    print(
        json.dumps(
            {
                "uid": claims.get("uid") or claims.get("sub"),
                "email": claims.get("email"),
                "email_verified": claims.get("email_verified"),
                "issued_at": claims.get("iat"),
                "expires_at": claims.get("exp"),
                "audience": claims.get("aud"),
                "issuer": claims.get("iss"),
            },
            indent=2,
        )
    )


def _check_uid(claims: dict[str, Any], expected: str | None) -> None:
    if expected and (claims.get("uid") or claims.get("sub")) != expected:
        raise SystemExit(f"uid mismatch: expected {expected}")
    if not (claims.get("uid") or claims.get("sub")):
        raise SystemExit("decoded token has no uid/sub claim")


def _verify_live_token(args: argparse.Namespace) -> None:
    token = args.token or os.getenv("FIREBASE_ID_TOKEN", "").strip()
    if not token:
        raise SystemExit("provide --token or set FIREBASE_ID_TOKEN")
    if not settings.FIREBASE_PROJECT_ID:
        raise SystemExit("set FIREBASE_PROJECT_ID to the project that issued the token")

    claims = _decode(token)
    _check_uid(claims, args.expected_uid)
    _print_claims(claims)
    print("Firebase ID token verified successfully.")


def _verify_with_emulator(args: argparse.Namespace) -> None:
    host = args.emulator_host or os.getenv("FIREBASE_AUTH_EMULATOR_HOST", "").strip()
    if not host:
        raise SystemExit("provide --emulator-host or set FIREBASE_AUTH_EMULATOR_HOST")
    if not settings.FIREBASE_PROJECT_ID:
        raise SystemExit("set FIREBASE_PROJECT_ID (any demo id is fine for the emulator)")

    os.environ["FIREBASE_AUTH_EMULATOR_HOST"] = host
    from firebase_admin import auth as firebase_auth

    # Initialise through the backend's own config so the emulator path is used.
    _get_firebase_app()

    email = f"verify-{secrets.token_hex(5)}@example.com"
    password = secrets.token_urlsafe(18)
    user = firebase_auth.create_user(email=email, password=password)
    try:
        response = httpx.post(
            f"http://{host}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword",
            params={"key": "fake-api-key"},
            json={"email": email, "password": password, "returnSecureToken": True},
            timeout=10.0,
        )
        response.raise_for_status()
        token = response.json()["idToken"]

        claims = _decode(token)
        _check_uid(claims, args.expected_uid or user.uid)
        if claims.get("email") != email:
            raise SystemExit(f"email mismatch: expected {email}")
        _print_claims(claims)
        print("Firebase Auth emulator token verified successfully.")
    finally:
        firebase_auth.delete_user(user.uid)


def _verify_with_test_user(args: argparse.Namespace) -> None:
    api_key = (
        os.getenv("FIREBASE_WEB_API_KEY") or os.getenv("WEB_API_KEY") or ""
    ).strip()
    if not api_key:
        raise SystemExit("set FIREBASE_WEB_API_KEY to the Firebase Web API key")
    if not settings.FIREBASE_PROJECT_ID:
        raise SystemExit("set FIREBASE_PROJECT_ID to the live project that issues tokens")
    if os.getenv("FIREBASE_AUTH_EMULATOR_HOST"):
        raise SystemExit("unset FIREBASE_AUTH_EMULATOR_HOST for a live-project check")

    from firebase_admin import auth as firebase_auth

    _get_firebase_app()
    email = f"verify-{secrets.token_hex(5)}@example.com"
    password = secrets.token_urlsafe(18)
    user = firebase_auth.create_user(email=email, password=password)
    try:
        response = httpx.post(
            "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword",
            params={"key": api_key},
            json={"email": email, "password": password, "returnSecureToken": True},
            timeout=20.0,
        )
        response.raise_for_status()
        token = response.json()["idToken"]

        claims = _decode(token)
        _check_uid(claims, args.expected_uid or user.uid)
        if claims.get("email") != email:
            raise SystemExit(f"email mismatch: expected {email}")
        _print_claims(claims)
        print("Live Firebase ID token verified successfully.")
    finally:
        firebase_auth.delete_user(user.uid)


def main() -> None:
    args = _parse_args()
    has_token = bool(args.token or os.getenv("FIREBASE_ID_TOKEN", "").strip())
    use_emulator = bool(args.emulator_host) or (
        not has_token
        and not args.create_test_user
        and bool(os.getenv("FIREBASE_AUTH_EMULATOR_HOST", "").strip())
    )
    if args.create_test_user:
        _verify_with_test_user(args)
    elif use_emulator:
        _verify_with_emulator(args)
    else:
        _verify_live_token(args)


if __name__ == "__main__":
    main()
