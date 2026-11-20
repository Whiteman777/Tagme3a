"""Catalog read/write service used by the v1 API."""

from decimal import Decimal

from sqlalchemy import Select, case, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload

from app.models.catalog import Merchant, Offer, PriceHistory, Product, ProductCategory
from app.schemas.catalog import (
    BestOffer,
    OfferRead,
    PricePoint,
    ProductCreate,
    ProductDetail,
    ProductListItem,
    ProductPage,
    ProductUpdate,
    SortOption,
)
from app.services.pricing import best_offer_reason, rank_offers
from app.services.search import search_service


class CatalogService:
    @staticmethod
    def _min_price_subquery():
        return (
            select(
                Offer.product_id.label("product_id"),
                func.min(Offer.price_egp).label("min_price"),
                func.count(Offer.id).label("offer_count"),
            )
            .where(Offer.in_stock.is_(True))
            .group_by(Offer.product_id)
            .subquery()
        )

    @staticmethod
    def _to_item(product: Product, min_price: Decimal | None, count: int) -> ProductListItem:
        return ProductListItem(
            id=product.id,
            slug=product.slug,
            category=product.category,
            brand=product.brand,
            model=product.model,
            name=product.name,
            name_ar=product.name_ar,
            image_url=product.image_url,
            lowest_price_egp=min_price,
            merchant_count=count,
        )

    async def list_products(
        self,
        db: AsyncSession,
        *,
        query: str | None = None,
        category: ProductCategory | None = None,
        brand: str | None = None,
        min_price: Decimal | None = None,
        max_price: Decimal | None = None,
        merchant_key: str | None = None,
        sort: SortOption = SortOption.PRICE_ASC,
        page: int = 1,
        page_size: int = 20,
    ) -> ProductPage:
        min_sq = self._min_price_subquery()
        stmt: Select = (
            select(Product, min_sq.c.min_price, min_sq.c.offer_count)
            .outerjoin(min_sq, min_sq.c.product_id == Product.id)
            .where(Product.is_active.is_(True))
        )
        backend = "database"

        if query:
            found = search_service.search(
                query,
                category=category.value if category else None,
                brand=brand,
                limit=page_size,
                offset=(page - 1) * page_size,
            )
            if found is not None:
                ids, _ = found
                backend = "meilisearch"
                stmt = stmt.where(Product.id.in_(ids or [-1]))
                if ids:
                    stmt = stmt.order_by(
                        case({pid: idx for idx, pid in enumerate(ids)}, value=Product.id)
                    )
            else:
                like = f"%{query}%"
                stmt = stmt.where(
                    or_(
                        Product.name.ilike(like),
                        Product.name_ar.ilike(like),
                        Product.brand.ilike(like),
                        Product.model.ilike(like),
                        Product.slug.ilike(like),
                    )
                )
        elif category:
            stmt = stmt.where(Product.category == category)
        if brand and backend == "database":
            stmt = stmt.where(Product.brand.ilike(brand))
        if min_price is not None:
            stmt = stmt.where(min_sq.c.min_price >= min_price)
        if max_price is not None:
            stmt = stmt.where(min_sq.c.min_price <= max_price)
        if merchant_key:
            stmt = stmt.where(
                Product.id.in_(
                    select(Offer.product_id)
                    .join(Merchant, Merchant.id == Offer.merchant_id)
                    .where(Merchant.key == merchant_key)
                )
            )

        if backend == "database":
            if sort == SortOption.PRICE_DESC:
                stmt = stmt.order_by(min_sq.c.min_price.desc().nullslast(), Product.id)
            elif sort == SortOption.RECENCY:
                stmt = stmt.order_by(Product.created_at.desc(), Product.id)
            elif sort == SortOption.NAME:
                stmt = stmt.order_by(Product.name.asc(), Product.id)
            else:
                stmt = stmt.order_by(min_sq.c.min_price.asc().nullslast(), Product.id)

        total = await db.scalar(select(func.count()).select_from(stmt.order_by(None).subquery()))
        rows = await db.execute(stmt.offset((page - 1) * page_size).limit(page_size))

        items = [
            self._to_item(product, price, count or 0) for product, price, count in rows.all()
        ]
        return ProductPage(
            items=items, total=int(total or 0), page=page, page_size=page_size,
            query=query, search_backend=backend,
        )

    async def get_detail(
        self, db: AsyncSession, *, product_id: int | None = None, slug: str | None = None
    ) -> ProductDetail | None:
        stmt = select(Product).where(Product.is_active.is_(True))
        if slug is not None:
            stmt = stmt.where(Product.slug == slug)
        elif product_id is not None:
            stmt = stmt.where(Product.id == product_id)
        else:
            return None

        stmt = stmt.options(joinedload(Product.offers).joinedload(Offer.merchant))
        result = await db.execute(stmt)
        product = result.unique().scalar_one_or_none()
        if product is None:
            return None

        best, ranked = rank_offers(list(product.offers))
        price_rows = await db.execute(
            select(PriceHistory)
            .where(PriceHistory.offer_id.in_([o.id for o in product.offers]))
            .order_by(PriceHistory.captured_at.desc())
            .limit(50)
        )
        history = list(price_rows.scalars().all())

        item = self._to_item(
            product,
            best.price_egp if best else None,
            len([o for o in product.offers if o.in_stock]),
        )
        detail = ProductDetail.model_validate(item)
        detail.description = product.description
        detail.specs = product.specs or {}
        detail.price_history = [
            PricePoint(
                price_egp=p.price_egp, in_stock=p.in_stock, captured_at=p.captured_at
            )
            for p in history
        ]
        if best:
            detail.best_offer = BestOffer(
                **OfferReadShape(best),
                reason=best_offer_reason(best),
                sponsored=False,
            )
        detail.offers = [OfferRead(**OfferReadShape(o)) for o in ranked]
        return detail

    async def get_price_history(
        self, db: AsyncSession, product_id: int, limit: int = 50
    ) -> list[PriceHistory]:
        result = await db.execute(
            select(PriceHistory)
            .join(Offer, Offer.id == PriceHistory.offer_id)
            .where(Offer.product_id == product_id)
            .order_by(PriceHistory.captured_at.desc())
            .limit(limit)
        )
        return list(result.scalars().all())

    async def create_product(self, db: AsyncSession, data: ProductCreate) -> Product:
        product = Product(**data.model_dump())
        db.add(product)
        await db.flush()
        await db.refresh(product)
        search_service.index_product(product)
        return product

    async def update_product(
        self, db: AsyncSession, product: Product, data: ProductUpdate
    ) -> Product:
        for field, value in data.model_dump(exclude_unset=True).items():
            setattr(product, field, value)
        await db.flush()
        await db.refresh(product)
        search_service.index_product(product)
        return product

    async def delete_product(self, db: AsyncSession, product: Product) -> None:
        search_service.delete_product(product.id)
        await db.delete(product)
        await db.flush()

    @staticmethod
    async def list_merchants(db: AsyncSession) -> list[Merchant]:
        result = await db.execute(select(Merchant).order_by(Merchant.name))
        return list(result.scalars().all())


def OfferReadShape(offer: Offer) -> dict:
    """Serialise an offer with its merchant (avoids circular schema imports)."""
    return {
        "id": offer.id,
        "url": offer.url,
        "price_egp": offer.price_egp,
        "in_stock": offer.in_stock,
        "last_seen_at": offer.last_seen_at,
        "merchant": {
            "id": offer.merchant.id,
            "key": offer.merchant.key,
            "name": offer.merchant.name,
            "name_ar": offer.merchant.name_ar,
            "base_url": offer.merchant.base_url,
            "is_active": offer.merchant.is_active,
        },
    }


catalog_service = CatalogService()
