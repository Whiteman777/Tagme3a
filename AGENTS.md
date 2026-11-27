# Agent profile — Tagme3aPriceBot/1.0

This is the public profile linked from our identifying User-Agent.

- **User-Agent:** `Tagme3aPriceBot/1.0 (+https://github.com/Whiteman777/Tagme3a)`
- **Purpose:** collect public EGP prices from merchant category HTML for the Tagme3a PC builder and price tracker.
- **Scope:** `robots.txt`-allowed public listing/category pages only. No cart, checkout, account, admin, AJAX or transactional paths. No personal data is collected.
- **Politeness:** 1s inter-request delay by default, `Retry-After` honoured on 429/503, dynamic pagination deduped and capped per seed (Sigma 3, Compumarts 14, 2B/Nekhely 6).
- **Authentication:** every request, including `robots.txt`, is signed with Web Bot Auth (RFC 9421 / `draft-ietf-webbotauth-httpsig-protocol-01`) when the worker has a private key.
- **Key directory:** `https://cdn.jsdelivr.net/gh/Whiteman777/Tagme3a@backend/backend/web_bot_auth_directory.json`
- **Current key id:** `9gML3-ZtKJdEPwdRPOAx-1b6G4c_2NoTjxt7VfB1p-Q`
- **Algorithm:** Ed25519; `Signature-Agent` uses the dictionary form with label `wba`; `Signature-Input` covers `@method`, `@target-uri`, `@authority`, the `signature-agent` member, `created`, `expires`, `keyid`, `alg`, `nonce` and `tag="web-bot-auth"`.
- **Rotation:** publish the new public JWK alongside the old one in the directory, switch the worker's `WEB_BOT_AUTH_PRIVATE_KEY`, then remove the old JWK. The directory URL stays stable.
- **Contact / reports:** open an issue at https://github.com/Whiteman777/Tagme3a/issues for access questions, rate concerns, or key compromise.

The public JWK directory contains no private material. The signing key is stored only in the worker environment (`WEB_BOT_AUTH_PRIVATE_KEY`) and is never committed.
