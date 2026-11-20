# Standalone mock API

An in-memory mock of the Tagme3a API for client development and tests. It needs
**no PostgreSQL, Firebase, Redis or Meilisearch**.

## Run

```bash
cd backend
uv run uvicorn app.mock_main:app --host 127.0.0.1 --port 8001 --reload
```

Interactive docs: <http://127.0.0.1:8001/docs>

## Endpoints

| Method | Path | Auth | Notes |
|---|---|---|---|
| `GET` | `/health`, `/ready` | no | Meta probes (`service: tagme3a-mock-api`) |
| `GET` | `/api/v1/products` | no | `q`, `category`, `brand`, `min_price`, `max_price`, `merchant`, `sort`, `page`, `page_size` |
| `GET` | `/api/v1/products/merchants` | no | Active merchants |
| `GET` | `/api/v1/products/{slug}` | no | Ranked offers + best offer + price history |
| `GET` | `/api/v1/products/{product_id}/price-history` | no | `limit` (1–500) |
| `POST` | `/api/v1/auth/sync` | yes | Fill empty profile fields |
| `GET` | `/api/v1/auth/me` | yes | Current in-memory profile |
| `POST` | `/api/v1/admin/products` | admin | 201 / 409 on duplicate slug |
| `PATCH` | `/api/v1/admin/products/{id}` | admin | Partial update |
| `DELETE` | `/api/v1/admin/products/{id}` | admin | 204 |

## Demo auth

Send `Authorization: Bearer <token>`. No real Firebase verification happens.

- `mock-admin-token` (or `admin`) → `admin`
- `mock-reviewer-token` (or `reviewer`) → `reviewer`
- any other token → `user`

Example:

```bash
curl -H 'Authorization: Bearer mock-admin-token' http://127.0.0.1:8001/api/v1/auth/me
```

## Behaviour notes

- 15 products across CPU/GPU/motherboard/RAM/PSU/case/storage/laptop, each with
  four merchant offers and three price-history points per offer.
- Best-offer selection reuses the **production** `app.services.pricing` rules:
  cheapest in-stock, fresh, high-confidence offer. Amazon offers are deliberately
  out of stock so the eligibility gate is visible.
- Arabic search terms work (e.g. `q=جيجابايت`).
- State lives per app process; restart resets all catalog edits and profiles.
- `create_app()` from `app.mock_main` returns a fresh isolated instance, used by
  the tests in `tests/test_mock_api.py`.

## Verify

```bash
cd backend
uv run ruff check .
uv run pytest -q -p no:logging
```
