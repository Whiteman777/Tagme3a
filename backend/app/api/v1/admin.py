"""Admin-only catalog management."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_admin
from app.core.db import get_db
from app.models.catalog import Product
from app.models.user import User
from app.schemas.catalog import ProductCreate, ProductDetail, ProductUpdate
from app.services.catalog import catalog_service

router = APIRouter(prefix="/admin", tags=["admin"])


@router.post("/products", response_model=ProductDetail, status_code=status.HTTP_201_CREATED)
async def create_product(
    data: ProductCreate,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(get_current_admin),
) -> ProductDetail:
    existing = await db.scalar(_product_by_slug(data.slug))
    if existing:
        raise HTTPException(status_code=409, detail="A product with this slug already exists")
    product = await catalog_service.create_product(db, data)
    detail = await catalog_service.get_detail(db, product_id=product.id)
    assert detail is not None
    return detail


@router.patch("/products/{product_id}", response_model=ProductDetail)
async def update_product(
    product_id: int,
    data: ProductUpdate,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(get_current_admin),
) -> ProductDetail:
    product = await db.get(Product, product_id)
    if product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    await catalog_service.update_product(db, product, data)
    detail = await catalog_service.get_detail(db, product_id=product_id)
    assert detail is not None
    return detail


@router.delete("/products/{product_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_product(
    product_id: int,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(get_current_admin),
) -> None:
    product = await db.get(Product, product_id)
    if product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    await catalog_service.delete_product(db, product)


def _product_by_slug(slug: str):
    from sqlalchemy import select

    return select(Product).where(Product.slug == slug)
