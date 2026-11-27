"""Idempotent development seed data for M1 catalog demo."""

from datetime import UTC, datetime, timedelta
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import AsyncSessionLocal
from app.core.logging import logger
from app.models.catalog import Merchant, Offer, PriceHistory, Product, ProductCategory
from app.services.search import search_service

MERCHANTS = [
    ("sigma", "Sigma Computer", "سيجما كمبيوتر", "https://sigma-computer.com", "sigma"),
    ("compumarts", "Compumarts", "كومبيومارتس", "https://www.compumarts.com", "compumarts"),
    ("nekhely", "El-Nekhely Technology", "النخلي للتكنولوجيا", "https://elnekhely.com", "nekhely"),
    ("amazon_eg", "Amazon.eg", "أمازون مصر", "https://amazon.eg", "amazon_eg"),
]

PRODUCTS = [
    (
        "ryzen-5-7600", ProductCategory.CPU, "AMD", "Ryzen 5 7600",
        "AMD Ryzen 5 7600", "إيه إم دي رايزن 5 7600",
        {"socket": "AM5", "cores": 6, "tdp": 65, "memory": "DDR5"},
    ),
    (
        "intel-i5-14600kf", ProductCategory.CPU, "Intel", "Core i5-14600KF",
        "Intel Core i5-14600KF", "إنتل كور i5-14600KF",
        {"socket": "LGA1700", "cores": 14, "tdp": 125, "memory": "DDR5"},
    ),
    (
        "ryzen-7-7800x3d", ProductCategory.CPU, "AMD", "Ryzen 7 7800X3D",
        "AMD Ryzen 7 7800X3D", "إيه إم دي رايزن 7 7800X3D",
        {"socket": "AM5", "cores": 8, "tdp": 120, "memory": "DDR5"},
    ),
    (
        "rtx-4060-windforce", ProductCategory.GPU, "Gigabyte", "RTX 4060 Windforce 8G",
        "Gigabyte GeForce RTX 4060 Windforce 8G",
        "جيجابايت RTX 4060 ويندفورس 8 جيجا",
        {"vram": "8GB", "length_mm": 272, "tdp": 115},
    ),
    (
        "rtx-4070-super", ProductCategory.GPU, "MSI", "RTX 4070 SUPER Ventus",
        "MSI GeForce RTX 4070 SUPER Ventus 12G",
        "إم إس آي RTX 4070 SUPER 12 جيجا",
        {"vram": "12GB", "length_mm": 308, "tdp": 220},
    ),
    (
        "rx-7800-xt", ProductCategory.GPU, "Sapphire", "RX 7800 XT Pulse",
        "Sapphire Radeon RX 7800 XT Pulse 16G",
        "سافاير RX 7800 XT 16 جيجا",
        {"vram": "16GB", "length_mm": 320, "tdp": 263},
    ),
    (
        "b650m-k", ProductCategory.MOTHERBOARD, "ASUS", "PRIME B650M-K",
        "ASUS PRIME B650M-K", "أسوس PRIME B650M-K",
        {"socket": "AM5", "memory": "DDR5", "form_factor": "mATX"},
    ),
    (
        "z790-a", ProductCategory.MOTHERBOARD, "MSI", "PRO Z790-A",
        "MSI PRO Z790-A DDR5", "إم إس آي PRO Z790-A",
        {"socket": "LGA1700", "memory": "DDR5", "form_factor": "ATX"},
    ),
    (
        "ddr5-16g-6000", ProductCategory.RAM, "Corsair", "VENGEANCE 16GB 6000",
        "Corsair VENGEANCE 16GB DDR5 6000", "كورسير 16 جيجا DDR5 6000",
        {"type": "DDR5", "capacity_gb": 16, "speed": 6000},
    ),
    (
        "ddr5-32g-6000", ProductCategory.RAM, "G.Skill", "Trident Z5 32GB",
        "G.Skill Trident Z5 32GB DDR5 6000", "جي سكيل 32 جيجا DDR5",
        {"type": "DDR5", "capacity_gb": 32, "speed": 6000},
    ),
    (
        "psu-750w-gold", ProductCategory.PSU, "Seasonic", "Focus GX-750",
        "Seasonic Focus GX-750 750W Gold", "سيزونيك 750 واط جولد",
        {"wattage": 750, "efficiency": "Gold", "form_factor": "ATX"},
    ),
    (
        "case-nzxt-h5", ProductCategory.CASE, "NZXT", "H5 Flow",
        "NZXT H5 Flow Mid Tower", "إن زد إكس تي H5",
        {"form_factor": "ATX", "max_gpu_mm": 365, "max_cooler_mm": 165},
    ),
    (
        "ssd-1tb-nvme", ProductCategory.STORAGE, "WD", "SN770 1TB",
        "WD Black SN770 1TB NVMe", "دبليو دي SN770 1 تيرا",
        {"interface": "NVMe", "capacity_gb": 1000},
    ),
    (
        "laptop-legion-5", ProductCategory.LAPTOP, "Lenovo", "Legion 5 R7000",
        "Lenovo Legion 5 (Ryzen 7 / RTX 4060)", "لينوفو ليجيون 5",
        {"cpu": "Ryzen 7 7840H", "gpu": "RTX 4060", "ram": "16GB", "screen": "15.6 165Hz"},
    ),
    (
        "laptop-tuf-a15", ProductCategory.LAPTOP, "ASUS", "TUF Gaming A15",
        "ASUS TUF Gaming A15 (Ryzen 7 / RTX 4050)", "أسوس TUF Gaming A15",
        {"cpu": "Ryzen 7 7435HS", "gpu": "RTX 4050", "ram": "16GB", "screen": "15.6 144Hz"},
    ),
]

BASE_PRICES = {
    "ryzen-5-7600": 8900,
    "intel-i5-14600kf": 12900,
    "ryzen-7-7800x3d": 16900,
    "rtx-4060-windforce": 18400,
    "rtx-4070-super": 31900,
    "rx-7800-xt": 26900,
    "b650m-k": 6100,
    "z790-a": 10500,
    "ddr5-16g-6000": 2600,
    "ddr5-32g-6000": 4900,
    "psu-750w-gold": 4300,
    "case-nzxt-h5": 3900,
    "ssd-1tb-nvme": 3100,
    "laptop-legion-5": 48900,
    "laptop-tuf-a15": 37900,
}

MARKET_MULTIPLIERS = [
    ("sigma", 1.0),
    ("compumarts", 1.045),
    ("nekhely", 1.02),
    ("amazon_eg", 1.075),
]


async def seed(db: AsyncSession) -> None:
    merchants: dict[str, Merchant] = {}
    for key, name, name_ar, base_url, adapter in MERCHANTS:
        merchant = await db.scalar(select(Merchant).where(Merchant.key == key))
        if merchant is None:
            merchant = Merchant(
                key=key,
                name=name,
                name_ar=name_ar,
                base_url=base_url,
                adapter_key=adapter,
                is_active=True,
            )
            db.add(merchant)
            await db.flush()
        merchants[key] = merchant

    created_products: list[Product] = []
    for slug, category, brand, model, name, name_ar, specs in PRODUCTS:
        product = await db.scalar(select(Product).where(Product.slug == slug))
        if product is None:
            product = Product(
                slug=slug,
                category=category,
                brand=brand,
                model=model,
                name=name,
                name_ar=name_ar,
                specs=specs,
                is_active=True,
            )
            db.add(product)
            await db.flush()
            created_products.append(product)

        base = Decimal(str(BASE_PRICES[slug]))
        for mkey, multiplier in MARKET_MULTIPLIERS:
            offer = await db.scalar(
                select(Offer).where(
                    Offer.product_id == product.id,
                    Offer.merchant_id == merchants[mkey].id,
                )
            )
            if offer is not None:
                continue

            price = (base * Decimal(str(multiplier))).quantize(Decimal("0.01"))
            offer = Offer(
                product_id=product.id,
                merchant_id=merchants[mkey].id,
                url=f"{merchants[mkey].base_url}/products/{slug}",
                price_egp=price,
                in_stock=mkey != "amazon_eg",
                match_confidence=Decimal("0.97"),
                last_seen_at=datetime.now(UTC),
            )
            db.add(offer)
            await db.flush()
            for days_ago, delta in [(6, 1.03), (3, 1.015), (0, 0.0)]:
                past_price = (base * Decimal(str(multiplier + delta))).quantize(Decimal("0.01"))
                db.add(
                    PriceHistory(
                        offer_id=offer.id,
                        price_egp=past_price,
                        in_stock=True,
                        source="seed",
                        captured_at=datetime.now(UTC) - timedelta(days=days_ago),
                    )
                )

    await db.commit()
    search_service.ensure_index()
    all_products = created_products or list((await db.scalars(select(Product))).all())
    search_service.index_products(all_products)
    logger.info("seed_complete", merchants=len(merchants), products=len(PRODUCTS))


async def main() -> None:
    async with AsyncSessionLocal() as db:
        await seed(db)


if __name__ == "__main__":  # pragma: no cover
    import asyncio

    asyncio.run(main())
