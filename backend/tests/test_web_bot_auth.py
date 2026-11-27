"""Web Bot Auth signing: RFC 9421 headers and Compumarts integration."""

from typing import Any

import httpx
import pytest
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec, ed25519, utils

from app.core.config import settings
from app.scrapers.compumarts import CompumartsScraper
from app.scrapers.web_bot_auth import (
    LABEL,
    WebBotAuthSigner,
    _jwk_thumbprint,
    key_directory,
)

AGENT_URL = "https://tagme3a.example/.well-known/http-message-signatures-directory"
TARGET = "https://www.compumarts.com/collections/pc-parts-proccesor?page=1"


def _pem(private_key: Any) -> str:
    return private_key.private_bytes(
        serialization.Encoding.PEM,
        serialization.PrivateFormat.PKCS8,
        serialization.NoEncryption(),
    ).decode("ascii")


def _params(header: str) -> str:
    value = header.removeprefix(f"{LABEL}=")
    return value[value.index(")") + 1 :]


def _signature(header: str) -> bytes:
    import base64

    return base64.b64decode(header.removeprefix(f"{LABEL}=:").removesuffix(":"))


def test_ed25519_headers_verify_with_public_key() -> None:
    private_key = ed25519.Ed25519PrivateKey.generate()
    signer = WebBotAuthSigner(agent_url=AGENT_URL, private_key=private_key)
    request = httpx.Request("GET", TARGET, headers={"User-Agent": "Tagme3aPriceBot/1.0"})

    headers = signer.sign(request, now=1_735_689_600).as_dict()

    params = _params(headers["Signature-Input"])
    assert 'tag="web-bot-auth"' in params
    assert 'alg="ed25519"' in params
    assert f'keyid="{_jwk_thumbprint(private_key)[0]}"' in params
    assert headers["Signature-Agent"] == f'{LABEL}="{AGENT_URL}"'
    private_key.public_key().verify(
        _signature(headers["Signature"]), signer.signature_base(request, params)
    )


def test_es256_signature_uses_raw_r_s_encoding() -> None:
    private_key = ec.generate_private_key(ec.SECP256R1())
    signer = WebBotAuthSigner(agent_url=AGENT_URL, private_key=private_key)
    request = httpx.Request("GET", TARGET)

    headers = signer.sign(request, now=1_735_689_600).as_dict()

    params = _params(headers["Signature-Input"])
    assert 'alg="ecdsa-p256-sha256"' in params
    signature = _signature(headers["Signature"])
    assert len(signature) == 64
    r = int.from_bytes(signature[:32], "big")
    s = int.from_bytes(signature[32:], "big")
    private_key.public_key().verify(
        utils.encode_dss_signature(r, s),
        signer.signature_base(request, params),
        ec.ECDSA(hashes.SHA256()),
    )


def test_public_directory_exposes_the_signing_key() -> None:
    private_key = ed25519.Ed25519PrivateKey.generate()
    directory = key_directory(private_key, expires_at=1_735_689_600)
    jwk = directory["keys"][0]

    assert jwk["kid"] == _jwk_thumbprint(private_key)[0]
    assert jwk["kty"] == "OKP"
    assert jwk["crv"] == "Ed25519"
    assert jwk["use"] == "sig"
    assert jwk["exp"] == 1_735_689_600


def test_partial_configuration_fails_closed() -> None:
    private_key = ed25519.Ed25519PrivateKey.generate()
    with pytest.MonkeyPatch.context() as patch:
        patch.setattr(settings, "WEB_BOT_AUTH_AGENT_URL", AGENT_URL)
        patch.setattr(settings, "WEB_BOT_AUTH_PRIVATE_KEY", "")
        patch.setattr(settings, "WEB_BOT_AUTH_KEY_ID", "")
        with pytest.raises(ValueError, match="both"):
            WebBotAuthSigner.from_settings()

        patch.setattr(settings, "WEB_BOT_AUTH_PRIVATE_KEY", _pem(private_key))
        assert WebBotAuthSigner.from_settings() is not None


def test_agent_url_must_be_https() -> None:
    with pytest.raises(ValueError, match="https"):
        WebBotAuthSigner(
            agent_url="http://tagme3a.example/jwks.json",
            private_key=ed25519.Ed25519PrivateKey.generate(),
        )


async def test_compumarts_fetch_adds_signed_headers(monkeypatch: Any) -> None:
    private_key = ed25519.Ed25519PrivateKey.generate()
    monkeypatch.setattr(settings, "WEB_BOT_AUTH_AGENT_URL", AGENT_URL)
    monkeypatch.setattr(settings, "WEB_BOT_AUTH_PRIVATE_KEY", _pem(private_key))
    monkeypatch.setattr(settings, "WEB_BOT_AUTH_KEY_ID", "")
    monkeypatch.setattr(settings, "WEB_BOT_AUTH_EXPIRES_SECONDS", 300)
    captured: list[httpx.Request] = []

    def handler(request: httpx.Request) -> httpx.Response:
        captured.append(request)
        if request.url.path == "/robots.txt":
            return httpx.Response(200, text="User-agent: *\nAllow: /")
        return httpx.Response(200, text="<html>ok</html>")

    async with httpx.AsyncClient(transport=httpx.MockTransport(handler)) as client:
        fetched = await CompumartsScraper(delay=0).fetch(TARGET, client)

    assert fetched.status_code == 200
    page = next(request for request in captured if request.url.path.endswith("pc-parts-proccesor"))
    assert page.headers["user-agent"] == "Tagme3aPriceBot/1.0 (+https://github.com/Whiteman777/Tagme3a)"
    assert page.headers["signature-agent"] == f'{LABEL}="{AGENT_URL}"'
    assert "signature-input" in page.headers
    assert "signature" in page.headers
    assert "signature" in captured[0].headers  # robots.txt is signed too
