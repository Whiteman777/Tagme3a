"""Auth and user schemas."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from app.models.user import UserRole


class AuthSyncIn(BaseModel):
    """Claims sent by the Flutter client after a successful Firebase sign-in."""

    email: EmailStr | None = None
    phone: str | None = Field(default=None, max_length=32)
    display_name: str | None = Field(default=None, max_length=120)
    photo_url: str | None = Field(default=None, max_length=1024)


class UserRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    email: str | None
    phone: str | None
    display_name: str | None
    photo_url: str | None
    role: UserRole
    created_at: datetime
    last_login_at: datetime | None
