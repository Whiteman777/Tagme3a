"""Web Bot Auth request signing for automated merchant traffic.

Implements ``draft-ietf-webbotauth-httpsig-protocol-01`` on top of RFC 9421:
``Signature``, ``Signature-Input`` and the dictionary-form ``Signature-Agent``
headers. Signing is asymmetric (Ed25519 or ES256), never HMAC, and is disabled
until an operator supplies an HTTPS directory URL and a private key.
"""

import base64
import hashlib
import json
import secrets
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any
from urllib.parse import urlsplit

import httpx
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec, ed25519, utils
from cryptography.hazmat.primitives.asymmetric.types import PrivateKeyTypes

from app.core.config import settings

LABEL = "wba"
_SIGNATURE_AGENT_COMPONENT = '"signature-agent";key="wba"'
_COMPONENTS = ('"@method"', '"@target-uri"', '"@authority"', _SIGNATURE_AGENT_COMPONENT)
_COMPONENT_LIST = "(" + " ".join(_COMPONENTS) + ")"
_EXPIRES_SECONDS = 300


def _b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def _sf_string(value: str) -> str:
    """Encode a Structured Fields String Item."""
    escaped = value.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def _load_private_key(raw: str) -> PrivateKeyTypes:
    text = raw.strip()
    if not text.startswith("-----BEGIN"):
        text = Path(text).read_text(encoding="utf-8")
    return serialization.load_pem_private_key(text.encode("utf-8"), password=None)


def _jwk_thumbprint(private_key: PrivateKeyTypes) -> tuple[str, str]:
    """Return ``(keyid, alg)`` for the supported asymmetric signing keys."""
    public = private_key.public_key()
    if isinstance(public, ed25519.Ed25519PublicKey):
        jwk: dict[str, str] = {
            "crv": "Ed25519",
            "kty": "OKP",
            "x": _b64url(
                public.public_bytes(serialization.Encoding.Raw, serialization.PublicFormat.Raw)
            ),
        }
        alg = "ed25519"
    elif isinstance(public, ec.EllipticCurvePublicKey) and isinstance(public.curve, ec.SECP256R1):
        numbers = public.public_numbers()
        size = (public.key_size + 7) // 8
        jwk = {
            "crv": "P-256",
            "kty": "EC",
            "x": _b64url(numbers.x.to_bytes(size, "big")),
            "y": _b64url(numbers.y.to_bytes(size, "big")),
        }
        alg = "ecdsa-p256-sha256"
    else:
        raise ValueError("Web Bot Auth requires an Ed25519 or P-256 private key")

    canonical = json.dumps(jwk, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return _b64url(hashlib.sha256(canonical).digest()), alg


def public_jwk(
    private_key: PrivateKeyTypes, *, key_id: str | None = None, expires_at: int | None = None
) -> dict[str, Any]:
    """Build the public JWK an origin can fetch from the agent directory.

    ``kid`` matches the thumbprint used in ``Signature-Input``. The optional
    ``expires_at`` supports key rotation without changing the directory URL.
    """
    derived_id, _ = _jwk_thumbprint(private_key)
    public = private_key.public_key()
    jwk: dict[str, Any] = {"kid": key_id or derived_id, "use": "sig"}
    if isinstance(public, ed25519.Ed25519PublicKey):
        jwk.update(
            kty="OKP",
            crv="Ed25519",
            alg="EdDSA",
            x=_b64url(
                public.public_bytes(serialization.Encoding.Raw, serialization.PublicFormat.Raw)
            ),
        )
    elif isinstance(public, ec.EllipticCurvePublicKey) and isinstance(public.curve, ec.SECP256R1):
        numbers = public.public_numbers()
        size = (public.key_size + 7) // 8
        jwk.update(
            kty="EC",
            crv="P-256",
            alg="ES256",
            x=_b64url(numbers.x.to_bytes(size, "big")),
            y=_b64url(numbers.y.to_bytes(size, "big")),
        )
    else:
        raise ValueError("Web Bot Auth requires an Ed25519 or P-256 private key")
    if expires_at is not None:
        jwk["exp"] = expires_at
    return jwk


def key_directory(private_key: PrivateKeyTypes, **kwargs: Any) -> dict[str, Any]:
    """Return the JWKS document served at the agent's well-known URL."""
    return {"keys": [public_jwk(private_key, **kwargs)]}


@dataclass(frozen=True)
class SignedHeaders:
    """The three headers required by Web Bot Auth."""

    signature: str
    signature_input: str
    signature_agent: str

    def as_dict(self) -> dict[str, str]:
        return {
            "Signature-Agent": self.signature_agent,
            "Signature-Input": self.signature_input,
            "Signature": self.signature,
        }


class WebBotAuthSigner:
    """Sign outbound GET requests with a per-agent asymmetric key."""

    def __init__(
        self,
        *,
        agent_url: str,
        private_key: PrivateKeyTypes,
        key_id: str | None = None,
        expires_seconds: int = _EXPIRES_SECONDS,
    ) -> None:
        if not agent_url.startswith("https://"):
            raise ValueError("WEB_BOT_AUTH_AGENT_URL must be an absolute https:// URL")
        if expires_seconds <= 0:
            raise ValueError("WEB_BOT_AUTH_EXPIRES_SECONDS must be positive")
        derived_id, alg = _jwk_thumbprint(private_key)
        self.agent_url = agent_url
        self.private_key = private_key
        self.key_id = key_id or derived_id
        self.alg = alg
        self.expires_seconds = expires_seconds

    @classmethod
    def from_settings(cls) -> "WebBotAuthSigner | None":
        """Return a signer only when Web Bot Auth is fully configured."""
        agent_url = settings.WEB_BOT_AUTH_AGENT_URL.strip()
        key_material = settings.WEB_BOT_AUTH_PRIVATE_KEY.strip()
        if not agent_url and not key_material:
            return None
        if not agent_url or not key_material:
            raise ValueError(
                "Set both WEB_BOT_AUTH_AGENT_URL and WEB_BOT_AUTH_PRIVATE_KEY "
                "to enable Web Bot Auth"
            )
        return cls(
            agent_url=agent_url,
            private_key=_load_private_key(key_material),
            key_id=settings.WEB_BOT_AUTH_KEY_ID.strip() or None,
            expires_seconds=settings.WEB_BOT_AUTH_EXPIRES_SECONDS,
        )

    def signature_base(self, request: httpx.Request, params: str) -> bytes:
        """Build the RFC 9421 signature base for ``request``."""
        parsed = urlsplit(str(request.url))
        authority = parsed.netloc.rsplit("@", 1)[-1]
        lines = (
            f'"@method": {request.method.upper()}',
            f'"@target-uri": {request.url}',
            f'"@authority": {authority}',
            f"{_SIGNATURE_AGENT_COMPONENT}: {_sf_string(self.agent_url)}",
            f'"@signature-params": {_COMPONENT_LIST}{params}',
        )
        return "\n".join(lines).encode("utf-8")

    def _sign(self, base: bytes) -> bytes:
        if isinstance(self.private_key, ed25519.Ed25519PrivateKey):
            return self.private_key.sign(base)
        if isinstance(self.private_key, ec.EllipticCurvePrivateKey) and isinstance(
            self.private_key.curve, ec.SECP256R1
        ):
            der = self.private_key.sign(base, ec.ECDSA(hashes.SHA256()))
            r, s = utils.decode_dss_signature(der)
            return r.to_bytes(32, "big") + s.to_bytes(32, "big")
        raise ValueError("Unsupported Web Bot Auth signing key")

    def sign(self, request: httpx.Request, *, now: int | None = None) -> SignedHeaders:
        """Return Web Bot Auth headers for a request."""
        created = int(now if now is not None else time.time())
        expires = created + self.expires_seconds
        nonce = _b64url(secrets.token_bytes(32))
        params = (
            f";created={created}"
            f';keyid="{self.key_id}"'
            f';alg="{self.alg}"'
            f";expires={expires}"
            f';nonce="{nonce}"'
            ';tag="web-bot-auth"'
        )
        signature_input = f"{LABEL}={_COMPONENT_LIST}{params}"
        signature = self._sign(self.signature_base(request, params))
        return SignedHeaders(
            signature=f"{LABEL}=:{base64.b64encode(signature).decode('ascii')}:",
            signature_input=signature_input,
            signature_agent=f"{LABEL}={_sf_string(self.agent_url)}",
        )


def request_headers(
    request: httpx.Request, *, user_agent: str, signer: WebBotAuthSigner | None
) -> dict[str, str]:
    """Build request headers, adding Web Bot Auth when a signer is present."""
    headers = {"User-Agent": user_agent}
    if signer is not None:
        headers.update(signer.sign(request).as_dict())
    return headers


def describe_config() -> dict[str, Any]:
    """Small helper for health/docs output; never exposes private key material."""
    return {
        "enabled": bool(settings.WEB_BOT_AUTH_AGENT_URL and settings.WEB_BOT_AUTH_PRIVATE_KEY),
        "agent_url": settings.WEB_BOT_AUTH_AGENT_URL or None,
        "expires_seconds": settings.WEB_BOT_AUTH_EXPIRES_SECONDS,
    }
