"""In-memory demo catalog used by the standalone mock API.

No PostgreSQL, Redis, Meilisearch or Firebase is involved. The data mirrors the
shape of the real API so a client can be developed against either backend.
"""

from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from decimal import Decimal
from typing import NamedTuple

from app.models.catalog import ProductCategory
from app.schemas.catalog import MerchantRead, PricePoint


class CatalogEntry(NamedTuple):
    slug: str
    category: ProductCategory
    brand: str
    model: str
    name: str
    name_ar: str
    base_egp: int
    specs: dict


MERCHANTS: list[MerchantRead] = [
    MerchantRead(
        id=1,
        key="sigma",
        name="Sigma Computer",
        name_ar="سيجما كمبيوتر",
        base_url="https://sigma-computer.com",
        is_active=True,
    ),
    MerchantRead(
        id=2,
        key="compumarts",
        name="Compumarts",
        name_ar="كومبيومارتس",
        base_url="https://www.compumarts.com",
        is_active=True,
    ),
    MerchantRead(
        id=3,
        key="nekhely",
        name="El-Nekhely Technology",
        name_ar="النخلي للتكنولوجيا",
        base_url="https://www.elnekhelytechnology.com",
        is_active=True,
    ),
    MerchantRead(
        id=4,
        key="2b",
        name="2B",
        name_ar="توبي",
        base_url="https://2b.com.eg",
        is_active=True,
    ),
]

# Multipliers produce distinct EGP prices per merchant. 2B is deliberately out
# of stock so the eligibility gate in pricing.py is exercised by the mock.
MERCHANT_MULTIPLIERS: tuple[tuple[str, float], ...] = (
    ("sigma", 1.0),
    ("compumarts", 1.045),
    ("nekhely", 1.02),
    ("2b", 1.075),
)

CATALOG: list[CatalogEntry] = [
    CatalogEntry(
        "ryzen-5-7600",
        ProductCategory.CPU,
        "AMD",
        "Ryzen 5 7600",
        "AMD Ryzen 5 7600",
        "إيه إم دي رايزن 5 7600",
        8900,
        {"socket": "AM5", "cores": 6, "tdp": 65},
    ),
    CatalogEntry(
        "intel-i5-14600kf",
        ProductCategory.CPU,
        "Intel",
        "Core i5-14600KF",
        "Intel Core i5-14600KF",
        "إنتل كور i5-14600KF",
        12900,
        {"socket": "LGA1700", "cores": 14, "tdp": 125},
    ),
    CatalogEntry(
        "ryzen-7-7800x3d",
        ProductCategory.CPU,
        "AMD",
        "Ryzen 7 7800X3D",
        "AMD Ryzen 7 7800X3D",
        "إيه إم دي رايزن 7 7800X3D",
        16900,
        {"socket": "AM5", "cores": 8, "tdp": 120},
    ),
    CatalogEntry(
        "rtx-4060-windforce",
        ProductCategory.GPU,
        "Gigabyte",
        "RTX 4060 Windforce 8G",
        "Gigabyte GeForce RTX 4060 Windforce 8G",
        "جيجابايت RTX 4060 ويندفورس 8 جيجا",
        18400,
        {"vram": "8GB", "tdp": 115},
    ),
    CatalogEntry(
        "rtx-4070-super",
        ProductCategory.GPU,
        "MSI",
        "RTX 4070 SUPER Ventus 12G",
        "MSI GeForce RTX 4070 SUPER Ventus 12G",
        "إم إس آي RTX 4070 SUPER 12 جيجا",
        31900,
        {"vram": "12GB", "tdp": 220},
    ),
    CatalogEntry(
        "rx-7800-xt",
        ProductCategory.GPU,
        "Sapphire",
        "RX 7800 XT Pulse 16G",
        "Sapphire Radeon RX 7800 XT Pulse 16G",
        "سافاير RX 7800 XT 16 جيجا",
        26900,
        {"vram": "16GB", "tdp": 263},
    ),
    CatalogEntry(
        "b650m-k",
        ProductCategory.MOTHERBOARD,
        "ASUS",
        "PRIME B650M-K",
        "ASUS PRIME B650M-K",
        "أسوس PRIME B650M-K",
        6100,
        {"socket": "AM5", "form_factor": "mATX"},
    ),
    CatalogEntry(
        "z790-a",
        ProductCategory.MOTHERBOARD,
        "MSI",
        "PRO Z790-A DDR5",
        "MSI PRO Z790-A DDR5",
        "إم إس آي PRO Z790-A",
        10500,
        {"socket": "LGA1700", "form_factor": "ATX"},
    ),
    CatalogEntry(
        "ddr5-16g-6000",
        ProductCategory.RAM,
        "Corsair",
        "VENGEANCE 16GB 6000",
        "Corsair VENGEANCE 16GB DDR5 6000",
        "كورسير 16 جيجا DDR5 6000",
        2600,
        {"type": "DDR5", "capacity_gb": 16},
    ),
    CatalogEntry(
        "ddr5-32g-6000",
        ProductCategory.RAM,
        "G.Skill",
        "Trident Z5 32GB",
        "G.Skill Trident Z5 32GB DDR5 6000",
        "جي سكيل 32 جيجا DDR5",
        4900,
        {"type": "DDR5", "capacity_gb": 32},
    ),
    CatalogEntry(
        "psu-750w-gold",
        ProductCategory.PSU,
        "Seasonic",
        "Focus GX-750",
        "Seasonic Focus GX-750 750W Gold",
        "سيزونيك 750 واط جولد",
        4300,
        {"wattage": 750, "efficiency": "Gold"},
    ),
    CatalogEntry(
        "case-nzxt-h5",
        ProductCategory.CASE,
        "NZXT",
        "H5 Flow",
        "NZXT H5 Flow Mid Tower",
        "إن زد إكس تي H5",
        3900,
        {"max_gpu_mm": 365},
    ),
    CatalogEntry(
        "ssd-1tb-nvme",
        ProductCategory.STORAGE,
        "WD",
        "SN770 1TB",
        "WD Black SN770 1TB NVMe",
        "دبليو دي SN770 1 تيرا",
        3100,
        {"interface": "NVMe", "capacity_gb": 1000},
    ),
    CatalogEntry(
        "laptop-legion-5",
        ProductCategory.LAPTOP,
        "Lenovo",
        "Legion 5 R7000",
        "Lenovo Legion 5 (Ryzen 7 / RTX 4060)",
        "لينوفو ليجيون 5",
        48900,
        {"cpu": "Ryzen 7 7840H", "gpu": "RTX 4060"},
    ),
    CatalogEntry(
        "laptop-tuf-a15",
        ProductCategory.LAPTOP,
        "ASUS",
        "TUF Gaming A15",
        "ASUS TUF Gaming A15 (Ryzen 7 / RTX 4050)",
        "أسوس TUF Gaming A15",
        37900,
        {"cpu": "Ryzen 7 7435HS", "gpu": "RTX 4050"},
    ),
]


@dataclass
class MockOffer:
    """Duck-typed stand-in for Offer so the production pricing rules can be reused."""

    id: int
    url: str
    price_egp: Decimal
    in_stock: bool
    match_confidence: Decimal
    last_seen_at: datetime
    merchant: MerchantRead


@dataclass
class MockProduct:
    """Duck-typed stand-in for Product used by the mock API."""

    id: int
    slug: str
    category: ProductCategory
    brand: str
    model: str
    name: str
    name_ar: str | None
    description: str | None
    image_url: str | None
    specs: dict
    is_active: bool
    created_at: datetime
    offers: list[MockOffer]


def build_catalog() -> tuple[list[MockProduct], dict[int, list[PricePoint]]]:
    """Build a fresh catalog and its price history (one copy per app instance)."""
    products: list[MockProduct] = []
    history: dict[int, list[PricePoint]] = {}
    offer_id = 0

    for product_id, entry in enumerate(CATALOG, start=1):
        offers: list[MockOffer] = []
        for merchant_key, multiplier in MERCHANT_MULTIPLIERS:
            offer_id += 1
            merchant = next(m for m in MERCHANTS if m.key == merchant_key)
            price = (Decimal(str(entry.base_egp)) * Decimal(str(multiplier))).quantize(
                Decimal("0.01")
            )
            offer = MockOffer(
                id=offer_id,
                url=f"{merchant.base_url}/products/{entry.slug}",
                price_egp=price,
                in_stock=merchant_key != "2b",
                match_confidence=Decimal("0.97"),
                last_seen_at=datetime.now(UTC),
                merchant=merchant,
            )
            offers.append(offer)
            history[offer.id] = [
                PricePoint(
                    price_egp=(price * Decimal(str(factor))).quantize(Decimal("0.01")),
                    in_stock=True,
                    captured_at=datetime.now(UTC) - timedelta(days=days),
                )
                for days, factor in ((6, 1.03), (3, 1.015), (0, 1.0))
            ]

        products.append(
            MockProduct(
                id=product_id,
                slug=entry.slug,
                category=entry.category,
                brand=entry.brand,
                model=entry.model,
                name=entry.name,
                name_ar=entry.name_ar,
                description=f"{entry.name} — demo catalog entry",
                image_url=None,
                specs=entry.specs,
                is_active=True,
                created_at=datetime.now(UTC),
                offers=offers,
            )
        )

    return products, history


PRODUCTS, PRICE_HISTORY = build_catalog()
