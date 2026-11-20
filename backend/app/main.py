"""Tagme3a FastAPI application entrypoint."""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api.v1.router import api_router
from app.core.config import settings
from app.core.db import engine
from app.core.logging import configure_logging, logger
from app.services.search import search_service

configure_logging()


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("startup", environment=settings.ENVIRONMENT)
    search_service.ensure_index()
    yield
    await engine.dispose()
    logger.info("shutdown")


app = FastAPI(
    title="Tagme3a API",
    description="Egyptian PC builder, laptop recommender and live multi-merchant price tracker.",
    version="0.1.0",
    lifespan=lifespan,
    docs_url="/docs",
    openapi_url="/openapi.json",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix=settings.API_V1_PREFIX)


@app.get("/health", tags=["meta"], summary="Liveness probe")
async def health() -> JSONResponse:
    return JSONResponse({"status": "ok", "service": "tagme3a-api", "version": "0.1.0"})


@app.get("/ready", tags=["meta"], summary="Readiness probe")
async def ready() -> JSONResponse:
    from sqlalchemy import text

    from app.core.db import AsyncSessionLocal

    try:
        async with AsyncSessionLocal() as session:
            await session.execute(text("SELECT 1"))
        db_ok = True
    except Exception as exc:  # noqa: BLE001
        logger.warning("readiness_db_failed", error=str(exc))
        db_ok = False
    return JSONResponse(
        status_code=200 if db_ok else 503,
        content={"status": "ready" if db_ok else "degraded", "database": db_ok},
    )
