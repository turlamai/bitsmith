# Bitsmith

**A local workbench for understanding and editing firmware images.**

**English** · [简体中文](README.zh-CN.md)

[Product homepage](https://jrtx.site/products/bitsmith/) · [Source](https://github.com/turlamai/bitsmith) · [Issues and feedback](https://github.com/turlamai/bitsmith/issues)

> **Development preview.** The engine and the desktop workbench are implemented and covered by tests, but there are no verified installers yet. Do not use it to prepare production firmware without independent verification. No purchase, trial expiry or paid feature gate is planned during this development phase.

## What it is for

Firmware engineers handling Intel HEX, Motorola S-record (S19/SREC) and raw BIN need to edit **memory images**, not records as arbitrary ASCII text. The long-term workflow is:

1. Parse input formats into an address-to-byte model and explain individual records.
2. Inspect ranges, holes, overlaps and record checksums before editing.
3. Make semantic changes, then regenerate valid records and checksums on save.
4. Perform routine operations: fill, offset, crop, merge, convert and CRC.

**Status:** the four workbench views (records, image, operations, learn) run against the Racket engine through the typed bridge — parsing, live checksum verification, semantic operations, format conversion, CRC presets and file open/save are implemented; packaging and per-platform release verification are not done yet.

## Platforms and getting started

Designed for macOS, Windows and Linux, using a Racket domain engine and a system-WebView UI via [Glaze](https://github.com/turlamai/glaze).

### Install from a release

Release assets (deb/rpm/AppImage/Flatpak/tar.gz, DMG/zip, MSI/zip) ship with each [tagged release](https://github.com/turlamai/bitsmith/releases). Verify the download before running it:

```bash
gh release download v<version> --repo turlamai/bitsmith --pattern 'bitsmith-<version>-macos-arm64.dmg'
gh release download v<version> --repo turlamai/bitsmith --pattern SHA256SUMS
shasum -a 256 -c SHA256SUMS --ignore-missing
```

The built-in **Check for updates** (records view, sidebar foot) only *notifies*: it verifies an Ed25519-signed update manifest and opens nothing by itself; the download and install stay in your hands.

**No installer has passed the family install-smoke gate yet**, so treat every package as a development build until the first verified release notes say otherwise.

## Data and privacy

The intended workflow is fully local. Firmware contents must not be sent to online converters or a cloud service; no account is part of the core design. Treat every edited image as untrusted until independent format, checksum and target-memory-map validation succeeds. Keep the original input and a backup.

## Related tools

[FlashPilot](https://github.com/turlamai/flashpilot) consumes firmware images during a declared ECU flashing workflow. Bitsmith prepares or inspects an image; FlashPilot owns communication with the ECU.

### Building from source

Requires [Racket](https://racket-lang.org/) 9.0+ with the `glaze` package installed (`raco pkg install --auto glaze`) and `crypto` (`raco pkg install --auto crypto`, needed by the update check).

```bash
raco test shared/engine/   # engine unit tests (round-trip verified samples)
raco glaze schema check    # API contract against the reviewed baseline
raco glaze verify          # native-window acceptance: loads, asserts, screenshots
racket main.rkt            # run the desktop workbench
```

## Development and feedback

Review current work in [Issues](https://github.com/turlamai/bitsmith/issues). Please report a minimal **synthetic** sample image, expected and actual addresses/checksums, and platform information; never upload confidential production firmware.

## License

AGPL-3.0; see [LICENSE](LICENSE). The current family decision is [delivery before monetization](https://github.com/turlamai/turlamai.github.io/blob/master/PORTFOLIO.md); it does not alter the source license.
