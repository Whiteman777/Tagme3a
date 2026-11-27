"""Scraping pipeline models: raw snapshots, staging listings and run health."""

from datetime import datetime
from decimal import Decimal
from enum import StrEnum

from sqlalchemy import (
    Boolean,
    DateTime,
    Enum,
    ForeignKey,
    Index,
    Integer,
    Numeric,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.db import Base
from app.models.catalog import ProductCategory


class ParseStatus(StrEnum):
    PENDING = "pending"
    PARSED = "parsed"
    FAILED = "failed"


class MatchStatus(StrEnum):
    UNMATCHED = "unmatched"
    AUTO_MATCHED = "auto_matched"
    MATCHED = "matched"
    REJECTED = "rejected"


class RunStatus(StrEnum):
    OK = "ok"
    PARTIAL = "partial"
    FAILED = "failed"


class RawSnapshot(Base):
    """Immutable HTML captured from a merchant page, retained for audit/reparse."""

    __tablename__ = "raw_snapshots"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    merchant_id: Mapped[int] = mapped_column(
        ForeignKey("merchants.id", ondelete="CASCADE"), index=True
    )
    url: Mapped[str] = mapped_column(String(2048))
    checksum: Mapped[str] = mapped_column(String(64))
    content: Mapped[str] = mapped_column(Text)
    status_code: Mapped[int | None] = mapped_column(Integer, nullable=True)
    parse_status: Mapped[ParseStatus] = mapped_column(
        Enum(
            ParseStatus,
            native_enum=False,
            values_callable=lambda enum: [member.value for member in enum],
        ),
        default=ParseStatus.PENDING,
        server_default="pending",
        index=True,
    )
    fetched_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    parsed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    attempts: Mapped[int] = mapped_column(Integer, default=0, server_default="0")
    error: Mapped[str | None] = mapped_column(Text, nullable=True)

    staging: Mapped[list["StagingListing"]] = relationship(
        back_populates="raw_snapshot", cascade="all, delete-orphan"
    )

    __table_args__ = (
        UniqueConstraint(
            "merchant_id", "url", "checksum", name="uq_raw_snapshot_merchant_url_checksum"
        ),
        Index("ix_raw_snapshot_merchant_fetched", "merchant_id", "fetched_at"),
    )


class StagingListing(Base):
    """A parsed merchant listing awaiting (or having received) product matching."""

    __tablename__ = "staging_listings"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    raw_snapshot_id: Mapped[int] = mapped_column(
        ForeignKey("raw_snapshots.id", ondelete="CASCADE"), index=True
    )
    merchant_id: Mapped[int] = mapped_column(
        ForeignKey("merchants.id", ondelete="CASCADE"), index=True
    )
    external_id: Mapped[str] = mapped_column(String(255))
    raw_title: Mapped[str] = mapped_column(String(500))
    normalized_name: Mapped[str | None] = mapped_column(String(500), nullable=True)
    brand: Mapped[str | None] = mapped_column(String(120), nullable=True)
    model: Mapped[str | None] = mapped_column(String(255), nullable=True)
    category: Mapped[ProductCategory | None] = mapped_column(
        Enum(
            ProductCategory,
            native_enum=False,
            values_callable=lambda enum: [member.value for member in enum],
        ),
        nullable=True,
    )
    price_egp: Mapped[Decimal] = mapped_column(Numeric(12, 2))
    currency: Mapped[str] = mapped_column(String(8), default="EGP", server_default="EGP")
    in_stock: Mapped[bool] = mapped_column(Boolean, default=True, server_default="true")
    url: Mapped[str] = mapped_column(String(2048))
    match_status: Mapped[MatchStatus] = mapped_column(
        Enum(
            MatchStatus,
            native_enum=False,
            values_callable=lambda enum: [member.value for member in enum],
        ),
        default=MatchStatus.UNMATCHED,
        server_default="unmatched",
        index=True,
    )
    match_confidence: Mapped[Decimal | None] = mapped_column(Numeric(5, 4), nullable=True)
    product_id: Mapped[int | None] = mapped_column(
        ForeignKey("products.id", ondelete="SET NULL"), nullable=True, index=True
    )
    suggested_product_id: Mapped[int | None] = mapped_column(
        ForeignKey("products.id", ondelete="SET NULL"), nullable=True, index=True
    )
    suggestion_confidence: Mapped[Decimal | None] = mapped_column(Numeric(5, 4), nullable=True)
    suggestion_reason: Mapped[str | None] = mapped_column(String(64), nullable=True)
    reviewed_by: Mapped[int | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    raw_snapshot: Mapped[RawSnapshot] = relationship(back_populates="staging")

    __table_args__ = (
        UniqueConstraint("merchant_id", "external_id", name="uq_staging_merchant_external"),
        Index("ix_staging_merchant_status", "merchant_id", "match_status"),
    )


class ScraperRun(Base):
    """One health metric per merchant scrape (feeds the M2 admin health view)."""

    __tablename__ = "scraper_runs"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    merchant_id: Mapped[int] = mapped_column(
        ForeignKey("merchants.id", ondelete="CASCADE"), index=True
    )
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    finished_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    status: Mapped[RunStatus] = mapped_column(
        Enum(
            RunStatus,
            native_enum=False,
            values_callable=lambda enum: [member.value for member in enum],
        ),
        default=RunStatus.PARTIAL,
        server_default="partial",
        index=True,
    )
    listings_found: Mapped[int] = mapped_column(Integer, default=0, server_default="0")
    listings_parsed: Mapped[int] = mapped_column(Integer, default=0, server_default="0")
    snapshots_new: Mapped[int] = mapped_column(Integer, default=0, server_default="0")
    duration_ms: Mapped[int | None] = mapped_column(Integer, nullable=True)
    error: Mapped[str | None] = mapped_column(Text, nullable=True)

    __table_args__ = (Index("ix_scraper_run_merchant_started", "merchant_id", "started_at"),)
