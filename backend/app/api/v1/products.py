"""Public catalog endpoints."""

from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_db
from app.models.catalog import ProductCategory
from app.schemas.catalog import (
    MerchantRead,
    PricePoint,
    ProductDetail,
    ProductPage,
    SortOption,
)
from app.services.catalog import catalog_service

router = APIRouter(prefix="/products", tags=["catalog"])


@router.get("", response_model=ProductPage, summary="Search / browse products")
async def list_products(
    q: str | None = Query(default=None, description="Arabic or English search terms"),
    category: ProductCategory | None = None,
    brand: str | None = None,
    min_price: Decimal | None = Query(default=None, ge=0),
    max_price: Decimal | None = Query(default=None, ge=0),
    merchant: str | None = Query(default=None, description="Merchant key"),
    sort: SortOption = SortOption.PRICE_ASC,
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
) -> ProductPage:
    return await catalog_service.list_products(
        db,
        query=q,
        category=category,
        brand=brand,
        min_price=min_price,
        max_price=max_price,
        merchant_key=merchant,
        sort=sort,
        page=page,
        page_size=page_size,
    )


@router.get("/merchants", response_model=list[MerchantRead], summary="List active merchants")
async def list_merchants(db: AsyncSession = Depends(get_db)) -> list[MerchantRead]:
    merchants = await catalog_service.list_merchants(db)
    return [MerchantRead.model_validate(m) for m in merchants]


@router.get("/{slug}", response_model=ProductDetail, summary="Product detail with offers")
async def get_product(slug: str, db: AsyncSession = Depends(get_db)) -> ProductDetail:
    detail = await catalog_service.get_detail(db, slug=slug)
    if detail is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
    return detail


@router.get("/{product_id}/price-history", response_model=list[PricePoint])
async def price_history(
    product_id: int,
    limit: int = Query(default=50, ge=1, le=500),
    db: AsyncSession = Depends(get_db),
) -> list[PricePoint]:
    rows = await catalog_service.get_price_history(db, product_id, limit)
    return [PricePoint.model_validate(r) for r in rows]
