"""Auth endpoints. Firebase owns credentials; this API owns the profile + role."""

from fastapi import APIRouter, Depends

from app.api.deps import get_current_user
from app.models.user import User
from app.schemas.auth import AuthSyncIn, UserRead

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post(
    "/sync", response_model=UserRead, summary="Upsert local profile after Firebase sign-in"
)
async def sync_profile(
    payload: AuthSyncIn,
    user: User = Depends(get_current_user),
) -> User:
    """Called by the client once after login; optional claims can enrich the profile."""
    for field, value in payload.model_dump(exclude_unset=True).items():
        if value is not None and getattr(user, field, None) in (None, ""):
            setattr(user, field, value)
    return user


@router.get("/me", response_model=UserRead, summary="Current user profile")
async def read_me(user: User = Depends(get_current_user)) -> User:
    return user
