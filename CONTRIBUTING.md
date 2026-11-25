# Contributing to Bitsmith

Thank you for looking under the hood. Bitsmith is free software (AGPL-3.0,
see [LICENSE](LICENSE)): by submitting a pull request you agree your
contribution is licensed under AGPL-3.0.

## Ground rules

1. **The prototype is the UI baseline.** `design/prototype/` holds the
   screens and `design/prototype/shared.css` is the single token source;
   `design/DESIGN.md` records semantic names and decisions only. Change the
   prototype before the implementation and land both in the same pull
   request. UI acceptance compares the real window against the prototype.
2. **The glaze schema is the contract.** `glaze.rktd` and
   `glaze-schema.json` own the reviewed contract between the Racket engine
   and the WebView. Run `raco glaze schema check --json` before merging an
   API change; regenerate the baseline only with `raco glaze schema write`
   and review the diff.
3. **The engine owns the product.** `shared/engine/` is the only place
   product logic lives; the page never decides a verdict on its own.
   `shared/spec.md` owns the scope and format matrix — change the contract
   and the implementation together. A change to the shared layer
   (`design/`, `shared/`) starts with an issue.
4. **Verdicts are arithmetic.** Every checksum and CRC claim is recomputed
   from bytes and round-trip verified against the synthetic samples in
   `shared/spec.md`. Embedded samples are always synthetic; a real or
   confidential firmware image never enters the repository.
5. **Explanations are product assets.** The teaching copy is maintained in
   two languages: frontend chrome strings in `public/i18n.js` (en + zh
   tables keyed by `data-i18n`) and engine-side explanations in
   `shared/i18n/`. Both tables stay key-aligned, and i18n keys are stable.
6. **Fail honestly.** Release steps `test -s` their outputs and schema
   gates fail on a breaking change. No silent fallbacks.

## Before you push

```bash
raco test shared/engine/                 # engine unit tests
raco test main.rkt shared/engine/main.rkt
raco glaze schema check --json           # API contract (zero breaking)
raco make main.rkt                       # the entry module compiles
python3 scripts/check-design-sync.py     # prototype ↔ implementation sync
bash scripts/check-release-version.sh    # VERSION = app-version = CHANGELOG
```

These mirror the CI jobs (`.github/workflows/ci.yml`, which also holds the
pinned Glaze commit to install alongside the `crypto` package).
`raco glaze verify` additionally opens the real WebView, asserts the
workspace contract, walks all four views and captures PNGs — run it before
a UI change and attach the captures to the pull request.

## Reporting issues

Include your OS and version, the Bitsmith version and installation shape
(DMG / zip / MSI / deb / rpm / AppImage / Flatpak / tar.gz), the image
format, and a minimal **synthetic** sample with expected and actual
addresses or checksums. Never upload confidential production firmware.
Security problems go through [SECURITY.md](SECURITY.md), not public issues.
