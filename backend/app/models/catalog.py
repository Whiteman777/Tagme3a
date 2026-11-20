"""Canonical catalog models: merchant, product, offer and append-only price history."""

from datetime import datetime
from decimal import Decimal
from enum import StrEnum

from sqlalchemy import (
    JSON,
    Boolean,
    DateTime,
    Enum,
    ForeignKey,
    Index,
    Numeric,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.db import Base


class ProductCategory(StrEnum):
    CPU = "cpu"
    GPU = "gpu"
    MOTHERBOARD = "motherboard"
    RAM = "ram"
    PSU = "psu"
    CASE = "case"
    COOLER = "cooler"
    STORAGE = "storage"
    LAPTOP = "laptop"
    PERIPHERAL = "peripheral"


class Merchant(Base):
    __tablename__ = "merchants"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    key: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(160))
    name_ar: Mapped[str | None] = mapped_column(String(160))
    base_url: Mapped[str] = mapped_column(String(1024))
    adapter_key: Mapped[str | None] = mapped_column(String(64))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, server_default="true")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    offers: Mapped[list["Offer"]] = relationship(back_populates="merchant")


class Product(Base):
    __tablename__ = "products"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    slug: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    category: Mapped[ProductCategory] = mapped_column(
        Enum(
            ProductCategory,
            native_enum=False,
            values_callable=lambda e: [m.value for m in e],
        ),
        index=True,
    )
    brand: Mapped[str] = mapped_column(String(120), index=True)
    model: Mapped[str] = mapped_column(String(255))
    name: Mapped[str] = mapped_column(String(400))
    name_ar: Mapped[str | None] = mapped_column(String(400))
    description: Mapped[str | None] = mapped_column(Text)
    image_url: Mapped[str | None] = mapped_column(String(1024))
    specs: Mapped[dict] = mapped_column(JSON, default=dict, server_default="{}")
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, server_default="true")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )

    offers: Mapped[list["Offer"]] = relationship(
        back_populates="product", cascade="all, delete-orphan"
    )

    __table_args__ = (
        Index("ix_products_category_brand", "category", "brand"),
    )


class Offer(Base):
    """One merchant's listing of one canonical product."""

    __tablename__ = "offers"
    __table_args__ = (
        UniqueConstraint("product_id", "merchant_id", name="uq_offers_product_merchant"),
    )

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    product_id: Mapped[int] = mapped_column(
        ForeignKey("products.id", ondelete="CASCADE"), index=True, nullable=False
    )
    merchant_id: Mapped[int] = mapped_column(
        ForeignKey("merchants.id", ondelete="CASCADE"), index=True, nullable=False
    )
    url: Mapped[str] = mapped_column(String(2048))
    price_egp: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False, index=True)
    in_stock: Mapped[bool] = mapped_column(Boolean, default=True, server_default="true", index=True)
    match_confidence: Mapped[Decimal | None] = mapped_column(Numeric(5, 4))
    first_seen_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    last_seen_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False, index=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )

    product: Mapped[Product] = relationship(back_populates="offers")
    merchant: Mapped[Merchant] = relationship(back_populates="offers")
    price_history: Mapped[list["PriceHistory"]] = relationship(
        back_populates="offer", cascade="all, delete-orphan"
    )


class PriceHistory(Base):
    """Append-only record. Never update or delete a row in normal operation."""

    __tablename__ = "price_history"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    offer_id: Mapped[int] = mapped_column(
        ForeignKey("offers.id", ondelete="CASCADE"), index=True, nullable=False
    )
    price_egp: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    in_stock: Mapped[bool] = mapped_column(Boolean, default=True, server_default="true")
    source: Mapped[str] = mapped_column(String(64), default="scraper", server_default="scraper")
    captured_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False, index=True
    )

    offer: Mapped[Offer] = relationship(back_populates="price_history")

    __table_args__ = (Index("ix_price_history_offer_time", "offer_id", "captured_at"),)
