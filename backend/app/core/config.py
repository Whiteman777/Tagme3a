"""Application settings loaded from environment variables."""

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

    # CORS
    CORS_ORIGINS: list[str] = Field(default_factory=lambda: ["*"])


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
