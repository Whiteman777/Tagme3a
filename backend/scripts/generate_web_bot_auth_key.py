"""Generate Web Bot Auth signing material for the Compumarts adapter.

Run from ``backend/``::

    uv run python -m scripts.generate_web_bot_auth_key --out-dir /secure/tagme3a-wba

The private key stays on the worker host. Publish the directory JSON at the
HTTPS URL configured in ``WEB_BOT_AUTH_AGENT_URL`` with media type
``application/http-message-signatures-directory+json``.
"""

import argparse
import json
import os
import stat
import time
from pathlib import Path

from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import ed25519

from app.scrapers.web_bot_auth import key_directory

DEFAULT_DAYS = 90


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out-dir", type=Path, default=Path("web_bot_auth"))
    parser.add_argument("--days", type=int, default=DEFAULT_DAYS)
    parser.add_argument("--force", action="store_true", help="overwrite an existing private key")
    return parser.parse_args()


def main() -> None:
    args = _parse_args()
    if args.days <= 0:
        raise SystemExit("--days must be positive")

    args.out_dir.mkdir(parents=True, exist_ok=True)
    private_path = args.out_dir / "web_bot_auth_private.pem"
    directory_path = args.out_dir / "http-message-signatures-directory.json"
    if private_path.exists() and not args.force:
        raise SystemExit(f"{private_path} already exists; use --force to rotate it")

    private_key = ed25519.Ed25519PrivateKey.generate()
    private_pem = private_key.private_bytes(
        serialization.Encoding.PEM,
        serialization.PrivateFormat.PKCS8,
        serialization.NoEncryption(),
    )
    private_path.write_bytes(private_pem)
    private_path.chmod(stat.S_IRUSR | stat.S_IWUSR)

    directory_path.write_text(
        json.dumps(
            key_directory(private_key, expires_at=int(time.time()) + args.days * 86_400),
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    os.chmod(directory_path, stat.S_IRUSR | stat.S_IWUSR | stat.S_IRGRP | stat.S_IROTH)

    print(f"private key: {private_path} (mode 0600; keep this on the worker only)")
    print(f"public directory: {directory_path}")
    print("set WEB_BOT_AUTH_AGENT_URL to the HTTPS URL serving the public directory")
    print(f"set WEB_BOT_AUTH_PRIVATE_KEY=/absolute/path/to/{private_path.name}")
    print("Content-Type: application/http-message-signatures-directory+json")
    print(f"rotate before the directory exp claim ({args.days} days)")


if __name__ == "__main__":
    main()
