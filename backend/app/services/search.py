"""Meilisearch indexing/search wrapper with graceful degradation.

If Meilisearch is unavailable the rest of the API keeps working via the
Postgres fallback in ``CatalogService``.
"""

from typing import Any

from meilisearch import Client

from app.core.config import settings
from app.core.logging import logger
from app.models.catalog import Product


class SearchService:
    def __init__(self) -> None:
        self._client: Client | None = None

    @property
    def client(self) -> Client:
        if self._client is None:
            self._client = Client(settings.MEILI_URL, settings.MEILI_MASTER_KEY or None)
        return self._client

    @staticmethod
    def _document(product: Product) -> dict[str, Any]:
        return {
            "id": product.id,
            "slug": product.slug,
            "name": product.name,
            "name_ar": product.name_ar or "",
            "brand": product.brand,
            "model": product.model,
            "category": product.category.value,
            "image_url": product.image_url or "",
            "specs_text": " ".join(str(v) for v in (product.specs or {}).values()),
            "is_active": product.is_active,
        }

    def ensure_index(self) -> bool:
        try:
            index = self.client.index(settings.MEILI_INDEX)
            index.update_searchable_attributes(
                ["name", "name_ar", "brand", "model", "specs_text", "slug"]
            )
            index.update_filterable_attributes(["category", "brand", "is_active"])
            index.update_sortable_attributes(["id"])
            return True
        except Exception as exc:  # noqa: BLE001
            logger.warning("meilisearch_unavailable", error=str(exc))
            return False

    def index_products(self, products: list[Product]) -> bool:
        if not products:
            return True
        try:
            index = self.client.index(settings.MEILI_INDEX)
            index.add_documents([self._document(p) for p in products], primary_key="id")
            return True
        except Exception as exc:  # noqa: BLE001
            logger.warning("meilisearch_index_failed", error=str(exc))
            return False

    def index_product(self, product: Product) -> bool:
        return self.index_products([product])

    def delete_product(self, product_id: int) -> None:
        try:
            self.client.index(settings.MEILI_INDEX).delete_document(product_id)
        except Exception as exc:  # noqa: BLE001
            logger.warning("meilisearch_delete_failed", id=product_id, error=str(exc))

    def search(
        self,
        query: str,
        *,
        category: str | None = None,
        brand: str | None = None,
        limit: int = 20,
        offset: int = 0,
    ) -> tuple[list[int], int] | None:
        """Return (ordered ids, estimated total) or None when unavailable."""
        filters: list[str] = ["is_active = true"]
        if category:
            filters.append(f'category = "{category}"')
        if brand:
            filters.append(f'brand = "{brand}"')

        try:
            result = self.client.index(settings.MEILI_INDEX).search(
                query,
                {
                    "filter": filters,
                    "limit": limit,
                    "offset": offset,
                    "attributesToRetrieve": ["id"],
                },
            )
        except Exception as exc:  # noqa: BLE001
            logger.warning("meilisearch_search_failed", error=str(exc))
            return None

        ids = [int(hit["id"]) for hit in result.get("hits", []) if "id" in hit]
        total = result.get("estimatedTotalHits", result.get("totalHits", len(ids)))
        return ids, int(total)


search_service = SearchService()
