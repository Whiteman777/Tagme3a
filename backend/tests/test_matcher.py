"""M3 matcher tests: normalization, hard gates, fuzzy aliases and suggestions."""

from decimal import Decimal

import pytest
from sqlalchemy import select

from app.core.config import settings
from app.core.db import AsyncSession
from app.models.catalog import Product, ProductAlias
from app.models.scraping import MatchStatus
from app.services.matcher import (
    canonical_text,
    embedding,
    learn_alias,
    match_listing,
    model_codes,
    vector_literal,
)


def test_normalization_splits_codes_and_drops_marketing_noise() -> None:
    assert canonical_text("Gigabyte GeForce RTX4060 WINDFORCE OC Graphics Card") == (
        "gigabyte rtx 4060 windforce"
    )
    assert model_codes("AMD Ryzen 5 7600X3D Processor") == frozenset({"7600x3d"})
    assert model_codes("Core i5-14600KF") == frozenset({"14600kf"})
    assert canonical_text("Intel® Core™ i5 processor 14600KF") == "intel core i5 14600kf"


def test_embedding_is_deterministic_and_normalized() -> None:
    first = embedding("AMD Ryzen 5 7600", dimensions=32)
    second = embedding("amd ryzen 5 7600", dimensions=32)

    assert first == second
    assert len(first) == 32
    assert abs(sum(value * value for value in first) - 1.0) < 0.001
    assert vector_literal(first).startswith("[")


async def test_fuzzy_variant_auto_matches_seeded_product(
    db: AsyncSession, seeded: None
) -> None:
    result = await match_listing(db, "Gigabyte GeForce RTX 4060 WINDFORCE OC 8G Graphics Card")

    assert result.status == MatchStatus.AUTO_MATCHED
    assert result.product is not None
    assert result.product.slug == "rtx-4060-windforce"
    assert result.confidence is not None and result.confidence >= settings.MATCH_AUTO_MIN


async def test_conflicting_model_codes_are_not_auto_matched(
    db: AsyncSession, seeded: None
) -> None:
    result = await match_listing(db, "AMD Ryzen 5 7600X3D Raphael AM5 Boxed Processor")

    assert result.status == MatchStatus.UNMATCHED
    assert result.product is None
    assert result.suggestion is None


@pytest.mark.parametrize(
    ("title", "brand", "wrong_slug"),
    [
        (
            "Gigabyte NVIDIA GeForce RTX 4060 Ti WINDFORCE OC Graphics Card",
            "Gigabyte",
            "rtx-4060-windforce",
        ),
        ("MSI GeForce RTX 4070 TI SUPER 16G GAMING X SLIM", "MSI", "rtx-4070-super"),
        ("NZXT H7 Flow ATX Mid Tower Case", "NZXT", "case-nzxt-h5"),
        ("Seasonic Prime TX-750 750W 80 Titanium Full Modular", "Seasonic", "psu-750w-gold"),
        ("DeepCool DQ750-M V2L 80+Gold", "DEEPCOOL", "psu-750w-gold"),
        (
            "RAM CORSAIR VENGEANCE DDR5 64GB 6000 CL40 Desktop Memory",
            "CORSAIR",
            "ddr5-16g-6000",
        ),
        ("HIKSEMI FUTURE 1TB PCIe 4.0 NVMe M.2 SSD", "HIKSEMI", "ssd-1tb-nvme"),
        ("MSI MAG Z790 TOMAHAWK WIFI DDR5 Motherboard", "MSI", "z790-a"),
    ],
)
async def test_similar_titles_are_not_false_positives(
    db: AsyncSession,
    seeded: None,
    title: str,
    brand: str,
    wrong_slug: str,
) -> None:
    result = await match_listing(db, title, brand=brand)

    assert result.status == MatchStatus.UNMATCHED
    assert result.product is None
    assert result.suggestion is None or result.suggestion.slug != wrong_slug


@pytest.mark.parametrize(
    ("title", "wrong_slug"),
    [
        (
            "G.Skill Trident Z5 RGB Series 64GB (2 x 32GB) DDR5 6000 MHz Memory Kit",
            "ddr5-32g-6000",
        ),
        (
            "G.Skill Trident Z5 Royal Neo RGB 32GB Kit (2x16GB) DDR5 8000MT/s CL38",
            "ddr5-32g-6000",
        ),
        (
            "Sapphire Pure AMD Radeon RX 7800 XT Gaming Graphics Card 16GB GDDR6",
            "rx-7800-xt",
        ),
        ("GIGABYTE GeForce RTX 4060 GAMING OC 8G GRAPHIC CARD", "rtx-4060-windforce"),
        ("MSI Gaming RTX 4070 Super 12G Gaming X Slim Graphics Card", "rtx-4070-super"),
    ],
)
async def test_capacity_speed_and_variant_conflicts_are_not_auto_matched(
    db: AsyncSession, seeded: None, title: str, wrong_slug: str
) -> None:
    result = await match_listing(db, title)

    assert result.status == MatchStatus.UNMATCHED
    assert result.product is None
    assert result.suggestion is None or result.suggestion.slug != wrong_slug


async def test_trademark_marks_do_not_break_auto_matching(
    db: AsyncSession, seeded: None
) -> None:
    result = await match_listing(db, "Intel® Core™ i5 processor 14600KF", brand="Intel")

    assert result.status == MatchStatus.AUTO_MATCHED
    assert result.product is not None and result.product.slug == "intel-i5-14600kf"


async def test_exact_capacity_kit_auto_matches(db: AsyncSession, seeded: None) -> None:
    result = await match_listing(
        db, "G.SKILL Trident Z5 Neo RGB DDR5 32GB (2x16GB) 6000MT/s CL30"
    )

    assert result.status == MatchStatus.AUTO_MATCHED
    assert result.product is not None and result.product.slug == "ddr5-32g-6000"


async def test_bundle_listing_is_never_auto_matched(db: AsyncSession, seeded: None) -> None:
    result = await match_listing(
        db,
        "R7-7800X3D/4070TI SUPER -BUILD- ASUS PRIME X670P WIFI - RYZEN 7 7800X3D Tray",
    )

    assert result.status == MatchStatus.UNMATCHED
    assert result.product is None
    assert result.reason == "bundle_or_combo"


async def test_low_confidence_returns_a_suggestion(
    db: AsyncSession, seeded: None, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setattr(settings, "MATCH_AUTO_MIN", Decimal("1.01"))
    monkeypatch.setattr(settings, "MATCH_REVIEW_MIN", Decimal("0.80"))

    result = await match_listing(db, "Gigabyte RTX 4060 WINDFORCE OC")

    assert result.status == MatchStatus.UNMATCHED
    assert result.product is None
    assert result.suggestion is not None
    assert result.suggestion.slug == "rtx-4060-windforce"
    assert result.suggestion_confidence is not None


async def test_learned_alias_is_reused(db: AsyncSession, seeded: None) -> None:
    product = await db.scalar(select(Product).where(Product.slug == "ryzen-5-7600"))
    assert product is not None

    assert await learn_alias(db, product, "R5 7600 Tray Bundle", reviewed_by=1)
    await db.flush()

    aliases = (await db.scalars(select(ProductAlias))).all()
    assert len(aliases) == 1
    assert aliases[0].source == "manual"

    result = await match_listing(db, "R5 7600 Tray Bundle")
    assert result.status == MatchStatus.AUTO_MATCHED
    assert result.product is not None and result.product.id == product.id
