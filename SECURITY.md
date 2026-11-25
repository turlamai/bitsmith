# Security Policy

Bitsmith is local by design: the workbench reads firmware images from your
disk, computes checksums, CRCs and structure views, and never uploads image
bytes anywhere. There is no telemetry. The engine is a Racket core; the UI is
a system WebView driven by typed routes — no arbitrary remote content is
rendered. No installers have shipped yet, so the update trust chain below is
infrastructure ahead of the first release.

## Reporting a vulnerability

Email **security@jrtx.site** (or open a GitHub security advisory on this
repository). Include reproduction steps, affected versions, and your
assessment of impact. You will get an acknowledgment within 72 hours.

Please do not open public issues for security problems.

## Scope

In scope:

- Firmware-image parsing and analysis: everything Bitsmith concludes from an
  untrusted image (`shared/engine/` — structure walkers, checksum/CRC
  verification and editing), including crafted or malicious images
- Update trust: verification of the Ed25519-signed `update-manifest.json`
  and its artifacts, key handling and rotation
  (`shared/engine/updater.rkt` — embedded public key and key id,
  `scripts/make-update-manifest.sh`, `scripts/update-keys.sh`)
- The carrier boundary: typed routes between the WebView and the engine,
  capability scoping (`host/main.rkt` per the glaze carrier contract)

Out of scope:

- Vulnerabilities in the firmware formats themselves, or in the devices the
  images came from
- Trustworthy-compute claims about analyzed firmware: Bitsmith reports what
  an image contains; it does not certify that the image is safe to flash

## Supported versions

The development preview on `main`. Security fixes land on `main` first;
once releases exist, fixes are backported to the latest release line.
