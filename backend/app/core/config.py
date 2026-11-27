"""Application settings loaded from environment variables."""

from decimal import Decimal
from functools import lru_cache

from pydantic import Field, PostgresDsn, RedisDsn
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=False,
    )

    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    API_V1_PREFIX: str = "/api/v1"

    # Database
    DATABASE_URL: PostgresDsn = Field(
        default="postgresql+asyncpg://tagme3a:tagme3a@localhost:5432/tagme3a"
    )
    DB_ECHO: bool = False

    # Redis
    REDIS_URL: RedisDsn = Field(default="redis://localhost:6379/0")

    # Meilisearch
    MEILI_URL: str = "http://localhost:7700"
    MEILI_MASTER_KEY: str = ""
    MEILI_INDEX: str = "products"

    # Firebase
    FIREBASE_PROJECT_ID: str = ""
    # Path to a service-account JSON file, or the JSON content itself.
    FIREBASE_CREDENTIALS: str = ""

    # Scraping
    SCRAPER_DELAY_SECONDS: float = 1.0
    SCRAPER_TIMEOUT_SECONDS: float = 15.0
    SCRAPER_MAX_RETRIES: int = 2
    SCRAPER_USER_AGENTS: list[str] = Field(
        default_factory=lambda: [
            "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/125.0",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0",
        ]
    )
    STALE_AFTER_HOURS: int = 24
    SCRAPE_CRON_HOUR: int = 2  # UTC (≈05:00 Cairo in summer, 04:00 in winter)
    SCRAPE_CRON_MINUTE: int = 0
    RECOMPUTE_CRON_MINUTE: int = 30

    # Scraper monitoring. Alerts are always logged; the webhook is optional.
    SCRAPER_ALERT_WEBHOOK_URL: str = ""
    SCRAPER_ALERT_FAILURE_LIMIT: int = 2
    SCRAPER_ALERT_THROTTLE_LIMIT: int = 3
    SCRAPER_ALERT_DROP_RATIO: float = 0.5

    # M3 matching (deterministic; no AI decisions)
    MATCH_AUTO_MIN: Decimal = Decimal("0.88")
    MATCH_REVIEW_MIN: Decimal = Decimal("0.72")
    MATCH_VECTOR_DIMS: int = 256

    # CORS
    CORS_ORIGINS: list[str] = Field(default_factory=lambda: ["*"])


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
