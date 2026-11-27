"""Tests for deterministic SKU candidate generation."""

from app.models.catalog import ProductCategory
from app.services.matcher import infer_category
from scripts.build_curated_sku_csv import (
    Sample,
    _brand_from_prefix,
    build_rows,
    category_from_url,
    choose_category,
    specs_for,
)


def test_category_from_compumarts_collection_url() -> None:
    assert (
        category_from_url(
            "https://www.compumarts.com/collections/pc-parts-proccesor?page=1"
        )
        is ProductCategory.CPU
    )
    assert (
        category_from_url("https://www.compumarts.com/collections/prebuilt-desktop-pcs")
        is ProductCategory.PREBUILT
    )


def test_specs_are_deterministic_and_price_relevant() -> None:
    assert specs_for(ProductCategory.RAM, "Corsair Vengeance 32GB DDR5 6000") == {
        "capacity_gb": 32,
        "speed": 6000,
        "type": "DDR5",
    }
    assert specs_for(ProductCategory.PSU, "Seasonic Focus GX-750 750W Gold") == {
        "wattage": 750,
        "efficiency": "Gold",
    }
    assert specs_for(ProductCategory.STORAGE, "WD SN770 1TB NVMe") == {
        "capacity_gb": 1024,
        "interface": "NVMe",
    }
    assert specs_for(
        ProductCategory.MOTHERBOARD, "MSI PRO B860M-E LGA 1851 DDR5 mATX Motherboard"
    ) == {
        "socket": "LGA1851",
        "memory": "DDR5",
        "form_factor": "MATX",
    }


def test_laptops_are_not_misclassified_as_gpus() -> None:
    assert (
        infer_category(
            "ASUS TUF Gaming A16 FA608UHI - AMD Ryzen 7 - NVIDIA GeForce RTX 5050 8GB"
        )
        is ProductCategory.LAPTOP
    )
    assert (
        infer_category("ASUS ROG G700TF Gaming Desktop - RTX 5070 - 32GB DDR5")
        is ProductCategory.PREBUILT
    )
    assert (
        infer_category(
            "Bundle AMD Ryzen 5 5600 - ASUS PRIME B550M-K - ASUS Dual GeForce RTX 5050"
        )
        is ProductCategory.PREBUILT
    )
    assert (
        infer_category("GIGABYTE C201 P Mid-Tower Case with GPU Clearance")
        is ProductCategory.CASE
    )
    assert (
        infer_category(
            "ASUS ProArt Z890-Creator WiFi Z890 LGA1851 Intel Core Ultra Processor Ready"
        )
        is ProductCategory.MOTHERBOARD
    )
    assert (
        infer_category("Dell Vostro 15 3530 Intel Core i5 8GB DDR4 512GB SSD")
        is ProductCategory.LAPTOP
    )
    assert (
        infer_category("Acer Predator Vesta II 16GB DDR5 6000MHz Desktop RAM")
        is ProductCategory.RAM
    )
    assert (
        infer_category("AMD Ryzen 9 9950X Desktop CPU, 16 Cores, AM5")
        is ProductCategory.CPU
    )
    assert (
        infer_category("Antec VX310 Mid Tower Case & PSU Combo")
        is ProductCategory.CASE
    )
    assert (
        infer_category("G.SKILL DDR4 RAM 16GB Desktop Computer Memory UDIMM")
        is ProductCategory.RAM
    )
    assert (
        infer_category("Crucial E100 1TB NVMe SSD for Laptops & Desktops")
        is ProductCategory.STORAGE
    )
    assert (
        infer_category("ASUS Prime X870-P AMD Ryzen Socket AM5 ATX Desktop Motherboard")
        is ProductCategory.MOTHERBOARD
    )
    assert (
        infer_category("ASUS TUF Gaming Desktop - Core i5 - RTX 5060 - 16GB RAM")
        is ProductCategory.PREBUILT
    )
    assert (
        infer_category("KLEVV Bolt X DDR4 16GB Gaming Desktop RAM Memory DIMM")
        is ProductCategory.RAM
    )
    assert (
        infer_category("MSI RTX 5060 Ti Graphics Card 16GB Desktop PC GPU")
        is ProductCategory.GPU
    )


def test_multiword_brand_prefix_is_detected() -> None:
    assert _brand_from_prefix("Cooler Master CMP 510 ATX Mid-Tower") == "cooler master"
    assert _brand_from_prefix("Bundle AMD Ryzen 5 5600 Tray") == "amd"


def test_title_votes_override_misleading_url_hint() -> None:
    laptop_on_gpu_page = Sample(
        "compumarts",
        "ASUS Vivobook Go 15 - Ryzen 5 - 8GB DDR5 - WIN11",
        "https://www.compumarts.com/collections/pc-parts-graphic-card?page=1",
    )
    assert choose_category([laptop_on_gpu_page]) is ProductCategory.LAPTOP


def test_build_rows_groups_aliases_and_limits_categories() -> None:
    groups = {
        "rtx 4070 ti super": [
            Sample("compumarts", "MSI RTX 4070 Ti SUPER Ventus", "https://m.test/g"),
            Sample("sigma", "MSI RTX 4070 Ti SUPER", "https://s.test/g"),
        ],
        "rtx 4060": [
            Sample("compumarts", "Gigabyte RTX 4060 Windforce", "https://m.test/g2"),
        ],
    }

    limited = build_rows(groups, min_count=1, limit_per_category=1)
    assert len(limited) == 1
    assert limited[0]["category"] == "gpu"
    assert limited[0]["count"] == 2
    assert "MSI RTX 4070 Ti SUPER" in limited[0]["aliases"]

    all_rows = build_rows(groups, min_count=1, limit_per_category=0)
    assert len(all_rows) == 2
