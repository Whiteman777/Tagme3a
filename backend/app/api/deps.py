"""Shared FastAPI dependencies."""

from datetime import UTC, datetime
from typing import Any

from fastapi import Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_db
from app.core.security import decode_token
from app.models.user import User, UserRole


async def get_current_user(
    payload: dict[str, Any] = Depends(decode_token),
    db: AsyncSession = Depends(get_db),
) -> User:
    """Resolve the Firebase identity to a local user row, creating it on first login."""
    uid = payload.get("uid") or payload.get("sub")
    if not uid:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token has no subject")

    result = await db.execute(select(User).where(User.firebase_uid == str(uid)))
    user = result.scalar_one_or_none()

    if user is None:
        user = User(
            firebase_uid=str(uid),
            email=payload.get("email"),
            phone=payload.get("phone_number"),
            display_name=payload.get("name"),
            photo_url=payload.get("picture"),
            role=UserRole.USER,
            last_login_at=datetime.now(UTC),
        )
        db.add(user)
    else:
        user.last_login_at = datetime.now(UTC)
        if not user.email and payload.get("email"):
            user.email = payload["email"]
        if not user.display_name and payload.get("name"):
            user.display_name = payload["name"]

    await db.flush()
    await db.refresh(user)
    return user


async def get_current_admin(user: User = Depends(get_current_user)) -> User:
    if user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Administrator access required.",
        )
    return user
