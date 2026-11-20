"""M0 smoke tests."""
from app.main import app


def test_openapi_contains_v1_routes() -> None:
    paths = app.openapi()["paths"]
    assert "/health" in paths
    assert "/api/v1/products" in paths
    assert "/api/v1/auth/me" in paths
