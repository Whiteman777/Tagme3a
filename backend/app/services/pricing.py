"""Offer eligibility and primary ('best') link selection.

Best practice: the cheapest *eligible* offer is primary. In-stock, fresh verification
and high match confidence are hard gates, not weights.
"""

from datetime import UTC, datetime, timedelta
from decimal import Decimal

from app.models.catalog import Offer

FRESHNESS_DAYS = 3
HIGH_CONFIDENCE = Decimal("0.80")


def _freshness_cutoff() -> datetime:
    return datetime.now(UTC) - timedelta(days=FRESHNESS_DAYS)


def is_eligible(offer: Offer) -> bool:
    if not offer.in_stock or not offer.url:
        return False
    if offer.match_confidence is not None and offer.match_confidence < HIGH_CONFIDENCE:
        return False
    seen = offer.last_seen_at
    if seen.tzinfo is None:
        seen = seen.replace(tzinfo=UTC)
    return seen >= _freshness_cutoff()


def rank_offers(offers: list[Offer]) -> tuple[Offer | None, list[Offer]]:
    """Return (best_offer, all_offers_ranked)."""
    eligible = [o for o in offers if is_eligible(o)]
    ineligible = [o for o in offers if not is_eligible(o)]

    def key(offer: Offer) -> tuple[object, ...]:
        seen = offer.last_seen_at
        if seen.tzinfo is None:
            seen = seen.replace(tzinfo=UTC)
        return (
            offer.price_egp,
            -(offer.match_confidence or Decimal("0")),
            -seen.timestamp(),
            offer.id,  # stable final tie-break
        )

    eligible.sort(key=key)
    ineligible.sort(key=lambda o: (o.price_egp, o.id))
    return (eligible[0] if eligible else None), eligible + ineligible


def best_offer_reason(offer: Offer) -> str:
    """Reason shown in the client for why this offer is primary."""
    return "lowest_price_in_stock" if offer.in_stock else "lowest_price_out_of_stock"
