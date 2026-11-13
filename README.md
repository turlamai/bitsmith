# ImageBench

**Understand and master firmware images — a local workbench for Intel HEX, Motorola S-record and raw BIN: record-level explanations, semantic editing with live checksum recalculation, and the operations FBL developers do daily (fill, offset, crop, merge, convert, CRC).**

English · [简体中文](README.zh-CN.md)

Status: early development (prototype stage). Built on the Racket engine with
a system-WebView resident UI (glaze line). Desktop-first: macOS, Windows and
Linux with equal standing. Local-only by design — firmware confidentiality is
a product principle, not a limitation.

## Why

FBL (flash bootloader) work means hex/s19/bin files that generic hex editors
can't edit safely (they see ASCII text, not a memory image), that CLI suites
handle with unmemorable options, and that online converters can't touch
(confidential firmware). ImageBench parses every format into one address→data
model: editing happens on the image, checksums and record structure are
recalculated on write, and every field explains itself.

## Related

[FlashPilot](https://github.com/turlamai/flashpilot) — the flashing side of
the workflow: UDS over CAN/DoIP/LIN driven by declarative flash plans.
ImageBench prepares images; FlashPilot flashes them.

## License

AGPL-3.0. See [LICENSE](LICENSE).
