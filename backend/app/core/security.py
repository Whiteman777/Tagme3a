"""Firebase ID token verification and role-based authorization dependencies."""

import json
import os
from collections.abc import Callable
from pathlib import Path
from typing import Any

import firebase_admin
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from firebase_admin import auth as firebase_auth
from firebase_admin import credentials

from app.core.config import settings
from app.core.logging import logger

_bearer = HTTPBearer(auto_error=False, description="Firebase ID token")
_firebase_app: firebase_admin.App | None = None


def _get_firebase_app() -> firebase_admin.App:
    """Lazily initialise the Firebase Admin SDK (single shared app)."""
    global _firebase_app
    if _firebase_app is not None:
        return _firebase_app

    if firebase_admin._apps:  # already initialised (e.g. by tests)
        _firebase_app = firebase_admin.get_app()
        return _firebase_app

    if not settings.FIREBASE_PROJECT_ID:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Firebase is not configured on this server.",
        )

    # The Auth emulator accepts unsigned tokens and needs no service account.
    if os.getenv("FIREBASE_AUTH_EMULATOR_HOST"):
        _firebase_app = firebase_admin.initialize_app(
            None, {"projectId": settings.FIREBASE_PROJECT_ID}
        )
        logger.info("firebase_emulator_connected", project=settings.FIREBASE_PROJECT_ID)
        return _firebase_app

    raw = settings.FIREBASE_CREDENTIALS.strip()
    if raw.startswith("{"):
        cred = credentials.Certificate(json.loads(raw))
    elif raw:
        path = Path(raw)
        if not path.is_file():
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Firebase credentials file not found.",
            )
        cred = credentials.Certificate(str(path))
    else:
        cred = credentials.ApplicationDefault()

    _firebase_app = firebase_admin.initialize_app(
        cred, {"projectId": settings.FIREBASE_PROJECT_ID}
    )
    logger.info("firebase_admin_initialised", project=settings.FIREBASE_PROJECT_ID)
    return _firebase_app


async def decode_token(
    bearer: HTTPAuthorizationCredentials | None = Depends(_bearer),
) -> dict[str, Any]:
    """Verify the Firebase ID token and return its decoded claims.

    Tests override this dependency, so no live Firebase project is required.
    """
    if bearer is None or not bearer.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication credentials were not provided.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    try:
        return firebase_auth.verify_id_token(
            bearer.credentials,
            app=_get_firebase_app(),
            check_revoked=False,
        )
    except Exception as exc:  # noqa: BLE001 - Firebase raises several exception types
        logger.warning("firebase_token_rejected", error=str(exc))
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired authentication token.",
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc


def require_roles(*allowed: str) -> Callable[..., Any]:
    """Build a dependency that restricts a route to the given role names."""

    async def _check(payload: dict[str, Any] = Depends(decode_token)) -> dict[str, Any]:
        # Roles are stored in Postgres, but custom claims (if present) are a fast path.
        claim_role = payload.get("role")
        if claim_role in allowed:
            return payload
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have permission to perform this action.",
        )

    return _check


require_admin = require_roles("admin")
