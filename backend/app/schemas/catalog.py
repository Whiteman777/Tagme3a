"""Catalog request/response schemas."""

from datetime import datetime
from decimal import Decimal
from enum import StrEnum

from pydantic import BaseModel, ConfigDict, Field, model_validator

from app.models.catalog import ProductCategory


class SortOption(StrEnum):
    PRICE_ASC = "price_asc"
    PRICE_DESC = "price_desc"
    RECENCY = "recency"
    NAME = "name"


class MerchantRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    key: str
    name: str
    name_ar: str | None
    base_url: str
    is_active: bool


class OfferRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    url: str
    price_egp: Decimal
    in_stock: bool
    last_seen_at: datetime
    merchant: MerchantRead


class BestOffer(OfferRead):
    reason: str = "lowest_price_in_stock"
    sponsored: bool = False


class PricePoint(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    price_egp: Decimal
    in_stock: bool
    captured_at: datetime


class ProductListItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    slug: str
    category: ProductCategory
    brand: str
    model: str
    name: str
    name_ar: str | None
    image_url: str | None
    lowest_price_egp: Decimal | None = None
    merchant_count: int = 0


class ProductDetail(ProductListItem):
    description: str | None = None
    specs: dict = Field(default_factory=dict)
    best_offer: BestOffer | None = None
    offers: list[OfferRead] = Field(default_factory=list)
    price_history: list[PricePoint] = Field(default_factory=list)


class ProductPage(BaseModel):
    items: list[ProductListItem]
    total: int
    page: int
    page_size: int
    query: str | None = None
    search_backend: str = "database"


class ProductCreate(BaseModel):
    slug: str = Field(min_length=1, max_length=255)
    category: ProductCategory
    brand: str = Field(min_length=1, max_length=120)
    model: str = Field(min_length=1, max_length=255)
    name: str = Field(min_length=1, max_length=400)
    name_ar: str | None = Field(default=None, max_length=400)
    description: str | None = None
    image_url: str | None = Field(default=None, max_length=1024)
    specs: dict = Field(default_factory=dict)

    @model_validator(mode="after")
    def _slug_is_lowercase(self) -> "ProductCreate":
        if self.slug != self.slug.lower():
            raise ValueError("slug must be lowercase")
        return self


class ProductUpdate(BaseModel):
    name: str | None = Field(default=None, max_length=400)
    name_ar: str | None = Field(default=None, max_length=400)
    description: str | None = None
    image_url: str | None = Field(default=None, max_length=1024)
    specs: dict | None = None
    is_active: bool | None = None
