"""Shared test fixtures: in-memory SQLite + fake Firebase identity."""

from collections.abc import AsyncGenerator

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.pool import StaticPool

from app.core.db import Base, get_db
from app.core.security import decode_token
from app.main import app
from app.models import Merchant, Offer, PriceHistory, Product, User  # noqa: F401

TEST_UID = "test-firebase-uid"
ADMIN_UID = "test-admin-uid"


@pytest.fixture
async def session_factory():
    engine = create_async_engine(
        "sqlite+aiosqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    yield factory
    await engine.dispose()


@pytest.fixture
async def db(session_factory) -> AsyncGenerator[AsyncSession, None]:
    async with session_factory() as session:
        yield session


@pytest.fixture
def auth_uid() -> str:
    return TEST_UID


@pytest.fixture
async def client(session_factory, auth_uid: str):
    async def override_get_db() -> AsyncGenerator[AsyncSession, None]:
        async with session_factory() as session:
            try:
                yield session
                await session.commit()
            except Exception:
                await session.rollback()
                raise

    async def override_decode_token() -> dict:
        return {
            "uid": auth_uid,
            "sub": auth_uid,
            "email": "tester@example.com",
            "name": "Test User",
        }

    app.dependency_overrides[get_db] = override_get_db
    app.dependency_overrides[decode_token] = override_decode_token

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as http_client:
        yield http_client
    app.dependency_overrides.clear()


@pytest.fixture
async def seeded(db: AsyncSession) -> None:
    from app.services.seed import seed

    await seed(db)
