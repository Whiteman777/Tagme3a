"""Standalone in-memory mock of the Tagme3a API.

Mirrors the real ``/api/v1`` contract without PostgreSQL, Firebase, Redis or
Meilisearch. Run it with:

    uvicorn app.mock_main:app --host 127.0.0.1 --port 8001

Demo auth: send ``Authorization: Bearer <token>`` to the auth/admin routes.

* ``mock-admin-token`` (or ``admin``) -> admin role
* ``mock-reviewer-token`` (or ``reviewer``) -> reviewer role
* any other token -> regular user

The real app verifies a Firebase ID token; this app only reads the bearer value.
"""

from copy import deepcopy
from dataclasses import dataclass
from datetime import UTC, datetime
from decimal import Decimal

from fastapi import APIRouter, Depends, FastAPI, HTTPException, Query, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app import mock_data
from app.models.catalog import ProductCategory
from app.models.user import UserRole
from app.schemas.auth import AuthSyncIn, UserRead
from app.schemas.catalog import (
    BestOffer,
    MerchantRead,
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

API_PREFIX = "/api/v1"
ADMIN_TOKENS = {"mock-admin-token", "admin"}
REVIEWER_TOKENS = {"mock-reviewer-token", "reviewer"}

_bearer = HTTPBearer(auto_error=False, description="Mock bearer token")


@dataclass
class MockUser:
    """In-memory profile matching the ``UserRead`` response shape."""

    id: int
    firebase_uid: str
    email: str | None
    phone: str | None
    display_name: str | None
    photo_url: str | None
    role: UserRole
    created_at: datetime
    last_login_at: datetime | None


@dataclass
class MockState:
    """Per-app mutable state; a fresh copy is created by :func:`create_app`."""

    products: list[mock_data.MockProduct]
    price_history: dict[int, list[PricePoint]]
    users: dict[str, MockUser]
    next_product_id: int


def _new_state() -> MockState:
    products = deepcopy(mock_data.PRODUCTS)
    return MockState(
        products=products,
        price_history=deepcopy(mock_data.PRICE_HISTORY),
        users={},
        next_product_id=max(p.id for p in products) + 1,
    )


def _state(request: Request) -> MockState:
    return request.app.state.mock


def _role_for_token(token: str) -> UserRole:
    if token in ADMIN_TOKENS:
        return UserRole.ADMIN
    if token in REVIEWER_TOKENS:
        return UserRole.REVIEWER
    return UserRole.USER


async def mock_current_user(
    request: Request,
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
) -> MockUser:
    """Replace Firebase verification with a simple demo bearer token."""
    if credentials is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing bearer token")

    token = credentials.credentials
    state = _state(request)
    user = state.users.get(token)
    if user is None:
        user = MockUser(
            id=len(state.users) + 1,
            firebase_uid=token,
            email=None,
            phone=None,
            display_name=None,
            photo_url=None,
            role=_role_for_token(token),
            created_at=datetime.now(UTC),
            last_login_at=None,
        )
        state.users[token] = user
    user.last_login_at = datetime.now(UTC)
    return user


async def mock_current_admin(user: MockUser = Depends(mock_current_user)) -> MockUser:
    if user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Administrator access required.",
        )
    return user


def _offer_shape(offer: mock_data.MockOffer) -> dict:
    """Serialise an offer with its merchant (mirrors ``OfferReadShape``)."""
    return {
        "id": offer.id,
        "url": offer.url,
        "price_egp": offer.price_egp,
        "in_stock": offer.in_stock,
        "last_seen_at": offer.last_seen_at,
        "merchant": offer.merchant.model_dump(),
    }


def _lowest_in_stock_price(product: mock_data.MockProduct) -> Decimal | None:
    prices = [offer.price_egp for offer in product.offers if offer.in_stock]
    return min(prices) if prices else None


def _effective_price(product: mock_data.MockProduct) -> Decimal:
    """Infinity stands in for 'no in-stock offer' when sorting."""
    return _lowest_in_stock_price(product) or Decimal("Infinity")


def _to_list_item(product: mock_data.MockProduct) -> ProductListItem:
    return ProductListItem(
        id=product.id,
        slug=product.slug,
        category=product.category,
        brand=product.brand,
        model=product.model,
        name=product.name,
        name_ar=product.name_ar,
        image_url=product.image_url,
        lowest_price_egp=_lowest_in_stock_price(product),
        merchant_count=len([o for o in product.offers if o.in_stock]),
    )


def _history_for(
    state: MockState, product: mock_data.MockProduct, limit: int = 50
) -> list[PricePoint]:
    points = [point for offer in product.offers for point in state.price_history.get(offer.id, [])]
    points.sort(key=lambda point: point.captured_at, reverse=True)
    return points[:limit]


def _to_detail(state: MockState, product: mock_data.MockProduct) -> ProductDetail:
    # The mock offer is duck-typed; pricing.py only accesses shared attributes.
    best, ranked = rank_offers(product.offers)  # type: ignore[arg-type]
    detail = ProductDetail.model_validate(_to_list_item(product))
    detail.description = product.description
    detail.specs = product.specs
    detail.lowest_price_egp = best.price_egp if best else None
    detail.offers = [OfferRead(**_offer_shape(offer)) for offer in ranked]
    detail.price_history = _history_for(state, product)
    if best:
        detail.best_offer = BestOffer(
            **_offer_shape(best),
            reason=best_offer_reason(best),  # type: ignore[arg-type]
            sponsored=False,
        )
    return detail


router = APIRouter(prefix=API_PREFIX)


@router.get("/products", response_model=ProductPage, tags=["catalog"], summary="Search products")
async def list_products(
    request: Request,
    q: str | None = Query(default=None, description="Arabic or English search terms"),
    category: ProductCategory | None = None,
    brand: str | None = None,
    min_price: Decimal | None = Query(default=None, ge=0),
    max_price: Decimal | None = Query(default=None, ge=0),
    merchant: str | None = Query(default=None, description="Merchant key"),
    sort: SortOption = SortOption.PRICE_ASC,
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
) -> ProductPage:
    products = [p for p in _state(request).products if p.is_active]

    if q:
        needle = q.casefold()
        products = [
            p
            for p in products
            if any(
                needle in (value or "").casefold()
                for value in (p.name, p.name_ar, p.brand, p.model, p.slug)
            )
        ]
    if category:
        products = [p for p in products if p.category == category]
    if brand:
        products = [p for p in products if brand.casefold() in p.brand.casefold()]
    if min_price is not None:
        products = [
            p
            for p in products
            if (price := _lowest_in_stock_price(p)) is not None and price >= min_price
        ]
    if max_price is not None:
        products = [
            p
            for p in products
            if (price := _lowest_in_stock_price(p)) is not None and price <= max_price
        ]
    if merchant:
        products = [p for p in products if any(o.merchant.key == merchant for o in p.offers)]

    if sort == SortOption.PRICE_DESC:
        products.sort(key=lambda p: (-_effective_price(p), p.id))
    elif sort == SortOption.RECENCY:
        products.sort(key=lambda p: (-p.created_at.timestamp(), p.id))
    elif sort == SortOption.NAME:
        products.sort(key=lambda p: (p.name.casefold(), p.id))
    else:
        products.sort(key=lambda p: (_effective_price(p), p.id))

    total = len(products)
    start = (page - 1) * page_size
    return ProductPage(
        items=[_to_list_item(p) for p in products[start : start + page_size]],
        total=total,
        page=page,
        page_size=page_size,
        query=q,
        search_backend="memory",
    )


@router.get(
    "/products/merchants",
    response_model=list[MerchantRead],
    tags=["catalog"],
    summary="List active merchants",
)
async def list_merchants() -> list[MerchantRead]:
    return [merchant for merchant in mock_data.MERCHANTS if merchant.is_active]


@router.get(
    "/products/{slug}",
    response_model=ProductDetail,
    tags=["catalog"],
    summary="Product detail with offers",
)
async def get_product(slug: str, request: Request) -> ProductDetail:
    state = _state(request)
    product = next((p for p in state.products if p.slug == slug and p.is_active), None)
    if product is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
    return _to_detail(state, product)


@router.get(
    "/products/{product_id}/price-history",
    response_model=list[PricePoint],
    tags=["catalog"],
    summary="Price points for a product",
)
async def price_history(
    request: Request,
    product_id: int,
    limit: int = Query(default=50, ge=1, le=500),
) -> list[PricePoint]:
    state = _state(request)
    product = next((p for p in state.products if p.id == product_id), None)
    if product is None:
        return []
    return _history_for(state, product, limit)


@router.post(
    "/auth/sync",
    response_model=UserRead,
    tags=["auth"],
    summary="Upsert local profile after sign-in",
)
async def sync_profile(
    payload: AuthSyncIn, user: MockUser = Depends(mock_current_user)
) -> MockUser:
    """Fill any empty profile fields, mirroring the real ``/auth/sync``."""
    for field, value in payload.model_dump(exclude_unset=True).items():
        if value is not None and getattr(user, field, None) in (None, ""):
            setattr(user, field, value)
    return user


@router.get("/auth/me", response_model=UserRead, tags=["auth"], summary="Current user profile")
async def read_me(user: MockUser = Depends(mock_current_user)) -> MockUser:
    return user


@router.post(
    "/admin/products",
    response_model=ProductDetail,
    tags=["admin"],
    status_code=status.HTTP_201_CREATED,
    summary="Create a product",
)
async def create_product(
    request: Request,
    data: ProductCreate,
    _admin: MockUser = Depends(mock_current_admin),
) -> ProductDetail:
    state = _state(request)
    if any(p.slug == data.slug for p in state.products):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="A product with this slug already exists",
        )
    product = mock_data.MockProduct(
        id=state.next_product_id,
        slug=data.slug,
        category=data.category,
        brand=data.brand,
        model=data.model,
        name=data.name,
        name_ar=data.name_ar,
        description=data.description,
        image_url=data.image_url,
        specs=data.specs,
        is_active=True,
        created_at=datetime.now(UTC),
        offers=[],
    )
    state.next_product_id += 1
    state.products.append(product)
    return _to_detail(state, product)


@router.patch(
    "/admin/products/{product_id}",
    response_model=ProductDetail,
    tags=["admin"],
    summary="Update a product",
)
async def update_product(
    request: Request,
    product_id: int,
    data: ProductUpdate,
    _admin: MockUser = Depends(mock_current_admin),
) -> ProductDetail:
    state = _state(request)
    product = next((p for p in state.products if p.id == product_id), None)
    if product is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(product, field, value)
    return _to_detail(state, product)


@router.delete(
    "/admin/products/{product_id}",
    tags=["admin"],
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a product",
)
async def delete_product(
    request: Request,
    product_id: int,
    _admin: MockUser = Depends(mock_current_admin),
) -> None:
    state = _state(request)
    product = next((p for p in state.products if p.id == product_id), None)
    if product is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
    state.products.remove(product)
    for offer in product.offers:
        state.price_history.pop(offer.id, None)


def create_app() -> FastAPI:
    """Build a mock app with a fresh in-memory catalog on every call."""
    application = FastAPI(
        title="Tagme3a Mock API",
        description="In-memory mock of the Tagme3a API — no external services required.",
        version="0.1.0",
        docs_url="/docs",
        openapi_url="/openapi.json",
    )
    application.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    application.state.mock = _new_state()
    application.include_router(router)

    @application.get("/health", tags=["meta"], summary="Liveness probe")
    async def health() -> dict[str, object]:
        return {
            "status": "ok",
            "service": "tagme3a-mock-api",
            "version": "0.1.0",
            "mock": True,
        }

    @application.get("/ready", tags=["meta"], summary="Readiness probe")
    async def ready() -> dict[str, object]:
        return {"status": "ready", "mode": "in-memory"}

    return application


app = create_app()
