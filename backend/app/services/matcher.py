"""Deterministic M3 matching: normalization, fuzzy scoring and optional pgvector.

This module never asks an AI model to decide a match. Scores come from string
similarity plus hard rule gates (brand, category, model identity, capacity and
bundle detection). A hashed trigram vector is stored in pgvector when the
extension is available, so the same rules work on plain Postgres/SQLite with
rapidfuzz alone. Vector similarity only proposes candidates; it can never
override a hard gate or auto-match by itself.
"""

import hashlib
import math
import re
import unicodedata
from collections import defaultdict
from dataclasses import dataclass
from decimal import Decimal

from rapidfuzz import fuzz
from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.catalog import Product, ProductAlias, ProductCategory
from app.models.scraping import MatchStatus

_ARABIC_DIGITS = str.maketrans("٠١٢٣٤٥٦٧٨٩", "0123456789")
_CODE_RE = re.compile(r"(?=[a-z0-9]*\d{3,})[a-z0-9]+")
_SPEC_CODE_RE = re.compile(r"^\d{1,5}(?:w|gb|tb|g|mm|mhz|ghz|v|a|ma)$")
_LEADING_CODE_RE = re.compile(r"^([a-z]{1,4})(\d{3,}[a-z]*)$")
_LETTER_RE = re.compile(r"^[a-z]{1,3}$")
_NUMBER_RE = re.compile(r"^\d{2,5}$")
_SHORT_MODEL_RE = re.compile(r"^(?=[a-z0-9]*\d)[a-z]{1,3}\d{1,4}[a-z]?$")
_CAPACITY_RE = re.compile(r"\b(\d{1,3})\s?(gb|tb|g)\b")
_MEMORY_SPEED_RE = re.compile(r"\b(\d{4,5})\s*(?:mt\s*s?|mhz)\b")
_BARE_SPEED_RE = re.compile(r"(?<!\d)(\d{4,5})(?!\d)")
_BUNDLE_RE = re.compile(r"\b(?:build|combo)\b|powered by")

_NOISE = frozenset(
    {
        "box",
        "boxed",
        "builder",
        "card",
        "cooler",
        "cpu",
        "desktop",
        "edition",
        "gaming",
        "geforce",
        "gpu",
        "graphics",
        "heatsink",
        "included",
        "not",
        "oc",
        "only",
        "pc",
        "processor",
        "pro",
        "series",
        "the",
        "tray",
        "unlocked",
        "version",
    }
)

_BRAND_ALIASES = {
    "abkoncore": "abkoncore",
    "acer": "acer",
    "adata": "adata",
    "addlink": "addlink",
    "aerocool": "aerocool",
    "apacer": "apacer",
    "amd": "amd",
    "antec": "antec",
    "apple": "apple",
    "asrock": "asrock",
    "asus": "asus",
    "be quiet": "be quiet",
    "bequiet": "be quiet",
    "biostar": "biostar",
    "colorful": "colorful",
    "cooler master": "cooler master",
    "coolermaster": "cooler master",
    "corsair": "corsair",
    "crucial": "crucial",
    "deepcool": "deepcool",
    "dell": "dell",
    "fractal design": "fractal design",
    "fractaldesign": "fractal design",
    "g skill": "g skill",
    "gainward": "gainward",
    "galax": "galax",
    "gigabyte": "gigabyte",
    "gskill": "g skill",
    "hp": "hp",
    "intel": "intel",
    "kingston": "kingston",
    "lg": "lg",
    "lexar": "lexar",
    "lenovo": "lenovo",
    "lian": "lian li",
    "lian li": "lian li",
    "lianli": "lian li",
    "logitech": "logitech",
    "maxsun": "maxsun",
    "msi": "msi",
    "montech": "montech",
    "nzxt": "nzxt",
    "palit": "palit",
    "patriot": "patriot",
    "phanteks": "phanteks",
    "pny": "pny",
    "powercolor": "powercolor",
    "razer": "razer",
    "redragon": "redragon",
    "samsung": "samsung",
    "sapphire": "sapphire",
    "seasonic": "seasonic",
    "silicon power": "silicon power",
    "siliconpower": "silicon power",
    "silver stone": "silver stone",
    "silverstone": "silver stone",
    "team": "team",
    "teamgroup": "team",
    "thermaltake": "thermaltake",
    "wd": "wd",
    "western digital": "wd",
    "xigmatek": "xigmatek",
    "xpg": "xpg",
    "zotac": "zotac",
}

# Tokens that variants append to a model code. They must remain part of the
# identity: an RTX 4060 Ti is not an RTX 4060, and an i5-14600K is not a KF.
_MODEL_SUFFIXES = frozenset(
    {"a", "d", "g", "k", "kf", "m", "r", "s", "super", "ti", "x", "x3d", "xt"}
)
_SERIES_TOKENS = frozenset({"i3", "i5", "i7", "i9", "r3", "r5", "r7", "r9", "ddr4", "ddr5", "ddr6"})
_FAMILY_PREFIXES = frozenset({"rtx", "rx", "gtx", "arc", "quadro", "radeon"})
_GENERIC_TOKENS = frozenset(set(_BRAND_ALIASES.values()) | {"plus", "new", "widget", "thing"})

_VECTOR_CANDIDATES = 8
_MIN_TOKEN_COVERAGE = 0.60
_VECTOR_WEIGHT = Decimal("0.85")
_CODE_BOOST = Decimal("0.02")


@dataclass(frozen=True)
class MatchResult:
    """Outcome of matching one staged listing to the curated catalog."""

    status: MatchStatus
    product: Product | None = None
    confidence: Decimal | None = None
    suggestion: Product | None = None
    suggestion_confidence: Decimal | None = None
    reason: str | None = None


def normalize(text: str | None) -> str:
    """Lowercase, de-accent and tokenize an AR/EN merchant title."""
    if not text:
        return ""
    # Drop trademark marks before NFKD: it decomposes "™" into "TM", which
    # would otherwise glue onto the preceding word ("Core™" -> "coretm").
    value = text.replace("™", " ").replace("®", " ").replace("٬", "").replace("٫", ".")
    value = unicodedata.normalize("NFKD", value)
    value = "".join(char for char in value if not unicodedata.combining(char))
    value = value.translate(_ARABIC_DIGITS)
    value = re.sub(r"[^a-z0-9]+", " ", value.casefold())
    return re.sub(r"\s+", " ", value).strip()


def canonical_text(text: str | None) -> str:
    """Normalized text with marketing noise removed and codes split out."""
    tokens: list[str] = []
    for token in normalize(text).split():
        if token in _NOISE:
            continue
        split = _LEADING_CODE_RE.match(token)
        tokens.append(f"{split.group(1)} {split.group(2)}" if split else token)
    return " ".join(tokens)


def _with_suffixes(tokens: list[str], index: int, code: str) -> str:
    """Append variant suffixes such as ``ti``, ``super`` or ``x3d`` to a code."""
    for following in tokens[index + 1 : index + 3]:
        if following not in _MODEL_SUFFIXES:
            break
        code += following
    return code


def model_codes(text: str | None) -> frozenset[str]:
    """Extract stable model identifiers such as ``7600x3d`` or ``4070tisuper``."""
    tokens = canonical_text(text).split()
    return frozenset(
        _with_suffixes(tokens, index, token)
        for index, token in enumerate(tokens)
        if _CODE_RE.fullmatch(token) and not _SPEC_CODE_RE.fullmatch(token)
    )


def identity_tokens(text: str | None) -> frozenset[str]:
    """Codes plus short model names (``h7``, ``gx750``) that distinguish SKUs."""
    tokens = canonical_text(text).split()
    identity = set(model_codes(text))
    for index, token in enumerate(tokens):
        if token in _SERIES_TOKENS or token in _GENERIC_TOKENS:
            continue
        if _SHORT_MODEL_RE.fullmatch(token):
            identity.add(_with_suffixes(tokens, index, token))
        elif (
            _LETTER_RE.fullmatch(token)
            and token not in _FAMILY_PREFIXES
            and index + 1 < len(tokens)
            and _NUMBER_RE.fullmatch(tokens[index + 1])
        ):
            identity.add(_with_suffixes(tokens, index + 1, token + tokens[index + 1]))
    return frozenset(identity)


def specific_identity(text: str | None) -> frozenset[str]:
    """Identity tokens containing letters (e.g. ``tx750``, ``z790a``)."""
    return frozenset(token for token in identity_tokens(text) if any(c.isalpha() for c in token))


def _capacity_gb(amount: str, unit: str) -> str:
    return f"{int(amount) * 1024 if unit == 'tb' else int(amount)}gb"


def capacity_tokens(text: str | None) -> frozenset[str]:
    """Normalize memory/storage capacities so 16 GB never matches 64 GB."""
    return frozenset(
        _capacity_gb(amount, unit) for amount, unit in _CAPACITY_RE.findall(normalize(text))
    )


def primary_capacity(text: str | None) -> str | None:
    """The headline capacity, which distinguishes a 64 GB kit from its 32 GB sticks."""
    match = _CAPACITY_RE.search(normalize(text))
    return _capacity_gb(*match.groups()) if match else None


def memory_speed_tokens(text: str | None) -> frozenset[str]:
    """DDR speed in MT/s or MHz; only compared when both sides state one."""
    value = normalize(text)
    explicit = _MEMORY_SPEED_RE.findall(value)
    if explicit:
        return frozenset(explicit)
    if re.search(r"\b(?:ddr[456]|memory|ram)\b", value):
        return frozenset(_BARE_SPEED_RE.findall(value))
    return frozenset()


def distinctive_tokens(text: str | None) -> frozenset[str]:
    """Variant words such as ``windforce`` or ``pulse`` that identify a SKU."""
    return frozenset(
        token
        for token in canonical_text(text).split()
        if len(token) >= 3
        and token.isalpha()
        and token not in _NOISE
        and token not in _GENERIC_TOKENS
        and token not in _FAMILY_PREFIXES
        and token not in _SERIES_TOKENS
        and token not in _MODEL_SUFFIXES
    )


def _signal_tokens(text: str | None) -> frozenset[str]:
    """Meaningful tokens that must overlap before fuzzy similarity counts."""
    return frozenset(
        token
        for token in canonical_text(text).split()
        if len(token) >= 3 and token not in _GENERIC_TOKENS
    )


def normalized_brand(brand: str | None) -> str:
    value = normalize(brand)
    return _BRAND_ALIASES.get(value, value)


def detected_brand(text: str | None) -> str:
    value = normalize(text)
    for alias in sorted(_BRAND_ALIASES, key=len, reverse=True):
        if re.search(rf"\b{re.escape(alias)}\b", value):
            return _BRAND_ALIASES[alias]
    return ""


def infer_category(text: str | None) -> ProductCategory | None:
    """Best-effort category hint used only as a hard gate when confident."""
    value = normalize(text)
    strong_prebuilt_markers = (
        "prebuilt",
        "pre built",
        "gaming desktop",
        "all in one pc",
        "all in one desktop",
    )
    component_phrases = (
        "desktop ram",
        "desktop memory",
        "desktop computer memory",
        "desktop pc gpu",
        "desktop pc case",
        "desktop processor",
        "desktop cpu",
        "desktop motherboard",
        "desktop cooler",
    )
    if (
        any(marker in value for marker in strong_prebuilt_markers)
        and not any(phrase in value for phrase in component_phrases)
        and not any(
            marker in value for marker in ("processor", "cpu", "motherboard", "cooler")
        )
    ):
        return ProductCategory.PREBUILT
    # "Desktop PC/Computer" also appears in component titles, so require a
    # system-level CPU/GPU indicator and exclude component nouns.
    if (
        "desktop" in value
        and not any(
            marker in value
            for marker in (
                "case",
                "processor",
                "cpu",
                "ram",
                "memory",
                "dimm",
                "motherboard",
                "cooler",
                "gpu",
                "graphics card",
            )
        )
        and any(
            marker in value
            for marker in (
                "core i",
                "core ultra",
                "intel core",
                "ryzen",
                "geforce",
                "rtx",
                "radeon",
                "win11",
                "windows 11",
            )
        )
    ):
        return ProductCategory.PREBUILT
    # Bundles contain several components, so they must never be mistaken for a
    # single GPU/CPU by a word such as "geforce" or "ryzen" later in the title.
    bundle_markers = ("bundle", "combo", "powered by")
    component_markers = (
        "processor",
        "ryzen",
        "core i",
        "motherboard",
        "geforce",
        "radeon",
        "power supply",
    )
    component_hits = sum(marker in value for marker in component_markers)
    if (
        any(marker in value for marker in bundle_markers)
        and component_hits >= 2
        and "motherboard" not in value
    ):
        return ProductCategory.PREBUILT
    laptop_markers = (
        "legion",
        "loq",
        "ideapad",
        "thinkpad",
        "vivobook",
        "zenbook",
        "pavilion",
        "elitebook",
        "probook",
        "chromebook",
        "omen",
        "victus",
        "inspiron",
        "vostro",
        "latitude",
        "xps",
        "tuf gaming a",
        "tuf gaming f",
        "rog ally",
        "windows 11",
        "win11",
        "15 inch",
        "16 inch",
        "15 6 inch",
    )
    if (
        "laptop" in value.split()
        or "notebook" in value.split()
        or any(marker in value for marker in laptop_markers)
    ):
        return ProductCategory.LAPTOP
    if (
        "graphics card" in value
        or "geforce" in value
        or "radeon" in value
        or re.search(r"\b(?:rtx|rx)\b", value)
    ):
        return ProductCategory.GPU
    if "motherboard" in value or re.search(
        r"\b(?:b550|b650|b760|b850|x670|x870|z690|z790|z890)\w*\b", value
    ):
        return ProductCategory.MOTHERBOARD
    if any(
        word in value for word in ("processor", "cpu", "ryzen", "threadripper", "core i")
    ):
        return ProductCategory.CPU
    if "ddr5" in value or "ddr4" in value or "memory" in value:
        return ProductCategory.RAM
    if "power supply" in value or re.search(r"\b\d{3,4}w\b", value):
        return ProductCategory.PSU
    if "nvme" in value or "ssd" in value or "m 2" in value or "hard drive" in value:
        return ProductCategory.STORAGE
    case_word = "case" in value.split()
    if (
        ("tower" in value and "cooler" not in value)
        or "computer case" in value
        or "chassis" in value
        or (case_word and "fan" not in value.split())
    ):
        return ProductCategory.CASE
    if "cooler" in value or "liquid cooling" in value or " aio" in value:
        return ProductCategory.COOLER
    if any(word in value.split() for word in ("keyboard", "mouse", "monitor", "headset")):
        return ProductCategory.PERIPHERAL
    return None


def embedding(text: str, *, dimensions: int | None = None) -> list[float]:
    """Deterministic hashed trigram vector; used only to propose candidates."""
    size = dimensions or settings.MATCH_VECTOR_DIMS
    vector = [0.0] * size
    value = canonical_text(text)
    for index in range(max(0, len(value) - 2)):
        trigram = value[index : index + 3]
        digest = hashlib.blake2b(trigram.encode("utf-8"), digest_size=8).digest()
        position = int.from_bytes(digest[:4], "big") % size
        vector[position] += 1.0 if digest[4] & 1 else -1.0
    magnitude = math.sqrt(sum(component * component for component in vector))
    if magnitude == 0:
        return vector
    return [round(component / magnitude, 6) for component in vector]


def vector_literal(values: list[float]) -> str:
    """pgvector text literal; passed through a SQL cast, not a Python adapter."""
    return "[" + ",".join(f"{value:.6f}" for value in values) + "]"


def _similarity(left: str, right: str) -> tuple[Decimal, str]:
    if left and left == right:
        return Decimal("1.0000"), "exact"
    scores = [
        (fuzz.WRatio(left, right) / 100, "fuzzy_title"),
        (fuzz.token_set_ratio(left, right) / 100, "token_set"),
        (fuzz.token_sort_ratio(left, right) / 100, "token_sort"),
    ]
    left_tokens, right_tokens = set(left.split()), set(right.split())
    if left_tokens and right_tokens and (
        left_tokens.issubset(right_tokens) or right_tokens.issubset(left_tokens)
    ):
        scores.append((0.94, "token_containment"))
    score, reason = max(scores, key=lambda item: item[0])
    return Decimal(str(score)).quantize(Decimal("0.0001")), reason


def _gates_pass(
    product: Product,
    *,
    listing_identity: frozenset[str],
    listing_specific: frozenset[str],
    listing_capacity: frozenset[str],
    listing_primary_capacity: str | None,
    listing_speed: frozenset[str],
    listing_brand: str,
    listing_category: ProductCategory | None,
) -> bool:
    product_text = " ".join(filter(None, [product.name, product.model, product.slug]))
    product_identity = identity_tokens(product_text)
    product_specific = specific_identity(product_text)
    if listing_specific and product_specific:
        if listing_specific.isdisjoint(product_specific):
            return False
    elif listing_identity and product_identity and listing_identity.isdisjoint(product_identity):
        return False
    product_capacity = capacity_tokens(product_text)
    if listing_capacity and product_capacity and listing_capacity.isdisjoint(product_capacity):
        return False
    product_primary = primary_capacity(product_text)
    if listing_primary_capacity and product_primary and listing_primary_capacity != product_primary:
        return False
    product_speed = memory_speed_tokens(product_text)
    if listing_speed and product_speed and listing_speed.isdisjoint(product_speed):
        return False
    product_brand = normalized_brand(product.brand)
    if listing_brand and product_brand and listing_brand != product_brand:
        return False
    return not (listing_category and product.category != listing_category)


def _product_texts(product: Product, aliases: list[str]) -> list[str]:
    texts = [
        product.name,
        product.model,
        f"{product.brand} {product.model}",
        product.slug.replace("-", " "),
    ]
    if product.name_ar:
        texts.append(product.name_ar)
    texts.extend(aliases)
    return texts


async def ensure_product_embeddings(db: AsyncSession) -> int:
    """Refresh deterministic vectors for active products (Postgres + pgvector only)."""
    bind = db.bind
    if bind is None or bind.dialect.name != "postgresql":
        return 0
    available = await db.scalar(text("SELECT 1 FROM pg_available_extensions WHERE name = 'vector'"))
    if not available:
        return 0
    exists = await db.scalar(text("SELECT to_regclass('product_embeddings')"))
    if not exists:
        return 0

    products = (
        await db.scalars(select(Product).where(Product.is_active.is_(True)).order_by(Product.id))
    ).all()
    if not products:
        return 0
    rows = [
        {
            "product_id": product.id,
            "embedding": vector_literal(
                embedding(
                    " ".join(
                        filter(None, [product.brand, product.name, product.model, product.slug])
                    )
                )
            ),
        }
        for product in products
    ]
    await db.execute(
        text(
            """
            INSERT INTO product_embeddings (product_id, embedding, updated_at)
            VALUES (:product_id, CAST(:embedding AS vector), now())
            ON CONFLICT (product_id) DO UPDATE
            SET embedding = EXCLUDED.embedding, updated_at = now()
            """
        ),
        rows,
    )
    return len(rows)


async def _vector_candidates(db: AsyncSession, listing_core: str) -> dict[int, Decimal]:
    bind = db.bind
    if bind is None or bind.dialect.name != "postgresql" or not listing_core:
        return {}
    exists = await db.scalar(text("SELECT to_regclass('product_embeddings')"))
    if not exists:
        return {}
    literal = vector_literal(embedding(listing_core))
    rows = (
        await db.execute(
            text(
                """
                SELECT product_id, 1 - (embedding <=> CAST(:query AS vector)) AS score
                FROM product_embeddings
                ORDER BY embedding <=> CAST(:query AS vector)
                LIMIT :limit
                """
            ),
            {"query": literal, "limit": _VECTOR_CANDIDATES},
        )
    ).all()
    return {
        int(product_id): Decimal(str(max(0.0, float(score)))).quantize(Decimal("0.0001"))
        for product_id, score in rows
    }


async def match_listing(
    db: AsyncSession,
    title: str,
    *,
    brand: str | None = None,
    category: ProductCategory | None = None,
    model: str | None = None,
) -> MatchResult:
    """Match a merchant listing to one curated product, or queue it for review."""
    raw = " ".join(filter(None, (brand, title, model)))
    if _BUNDLE_RE.search(normalize(raw)):
        return MatchResult(status=MatchStatus.UNMATCHED, reason="bundle_or_combo")

    listing_core = canonical_text(raw)
    listing_identity = identity_tokens(raw)
    listing_specific = specific_identity(raw)
    listing_capacity = capacity_tokens(raw)
    listing_primary_capacity = primary_capacity(raw)
    listing_speed = memory_speed_tokens(raw)
    listing_signal = _signal_tokens(raw)
    listing_brand = normalized_brand(brand) or detected_brand(raw)
    listing_category = category or infer_category(raw)

    products = (
        await db.scalars(select(Product).where(Product.is_active.is_(True)).order_by(Product.id))
    ).all()
    alias_rows = (
        await db.execute(select(ProductAlias.product_id, ProductAlias.normalized))
    ).all()
    aliases: dict[int, list[str]] = defaultdict(list)
    for product_id, alias in alias_rows:
        aliases[product_id].append(alias)

    vector_scores = await _vector_candidates(db, listing_core)
    best: tuple[Decimal, Product, str] | None = None
    for product in products:
        if not _gates_pass(
            product,
            listing_identity=listing_identity,
            listing_specific=listing_specific,
            listing_capacity=listing_capacity,
            listing_primary_capacity=listing_primary_capacity,
            listing_speed=listing_speed,
            listing_brand=listing_brand,
            listing_category=listing_category,
        ):
            continue

        candidate_texts = _product_texts(product, aliases[product.id])
        product_signal = _signal_tokens(" ".join(candidate_texts))
        if listing_signal and product_signal and listing_signal.isdisjoint(product_signal):
            continue
        variants = distinctive_tokens(product.model)

        score, reason = Decimal("0"), ""
        for candidate_text in candidate_texts:
            candidate_identity = identity_tokens(candidate_text)
            is_alias = candidate_text in aliases[product.id]
            if not is_alias and variants and listing_signal.isdisjoint(variants):
                continue
            if candidate_identity:
                if listing_identity and candidate_identity.isdisjoint(listing_identity):
                    continue
            elif not is_alias:
                # Generic slugs such as "ssd 1tb nvme" cannot decide a SKU.
                continue
            candidate_normalized = canonical_text(candidate_text)
            candidate_signal = _signal_tokens(candidate_text)
            if listing_signal and candidate_signal:
                coverage = len(listing_signal & candidate_signal) / len(candidate_signal)
                if coverage < _MIN_TOKEN_COVERAGE:
                    continue
            candidate_score, candidate_label = _similarity(listing_core, candidate_normalized)
            if candidate_score > score:
                score, reason = candidate_score, candidate_label

        vector_score = vector_scores.get(product.id)
        if vector_score is not None:
            weighted = (vector_score * _VECTOR_WEIGHT).quantize(Decimal("0.0001"))
            if weighted > score:
                score, reason = weighted, "vector_similarity"
        if (
            listing_identity
            and listing_identity.intersection(
                identity_tokens(" ".join(filter(None, [product.name, product.model, product.slug])))
            )
            and score < Decimal("0.90")
        ):
            score = min(Decimal("1.0000"), score + _CODE_BOOST)
        score = score.quantize(Decimal("0.0001"))
        if best is None or score > best[0]:
            best = (score, product, reason)

    if best is None:
        return MatchResult(status=MatchStatus.UNMATCHED, reason="no_candidate")
    score, product, reason = best
    if score >= settings.MATCH_AUTO_MIN:
        return MatchResult(
            status=MatchStatus.AUTO_MATCHED,
            product=product,
            confidence=score,
            reason=reason,
        )
    if score >= settings.MATCH_REVIEW_MIN:
        return MatchResult(
            status=MatchStatus.UNMATCHED,
            suggestion=product,
            suggestion_confidence=score,
            reason=reason,
        )
    return MatchResult(status=MatchStatus.UNMATCHED, reason="low_confidence")


async def learn_alias(
    db: AsyncSession,
    product: Product,
    title: str,
    *,
    reviewed_by: int | None = None,
    source: str = "manual",
) -> bool:
    """Persist a reviewer-approved title variant for future fuzzy matches."""
    normalized = canonical_text(title)
    if not normalized or len(normalized) > 300:
        return False
    alias = title.strip()[:300]
    existing = await db.scalar(
        select(ProductAlias.id).where(
            ProductAlias.product_id == product.id, ProductAlias.normalized == normalized
        )
    )
    if existing is not None:
        return False
    db.add(
        ProductAlias(
            product_id=product.id,
            alias=alias,
            normalized=normalized,
            source=source,
            created_by=reviewed_by,
        )
    )
    return True
