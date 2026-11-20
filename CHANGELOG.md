# Changelog

All notable changes to Bitsmith are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions are
semver. The signed update feed (update-manifest.json) is produced from
this file's release section.

## [0.1.0] - 2026-11-19

### Added

- Workbench implemented per the prototype baseline (issue #3): records,
  image, operations and learn views over a Racket engine through the
  typed bridge.
- Formats: Intel HEX, Motorola S-record (S0-S9) and raw BIN with an
  explicit base assumption; content sniffing decides the format
  (extensions lie); ELF32/ELF64 read-only summary.
- Live checksum verification with the arithmetic shown; malformed lines
  and failed checksums are preserved verbatim, never silently repaired.
- Operations: fill, pad-to-alignment, offset, crop, merge (widest-gap
  split; overlap blocks apply), convert (HEX / S-record S1-S3 with
  width-loss blocking / BIN materialising gaps) - every edit previews
  with a byte-level diff and canonical record counts; apply gates behind
  a confirmation; a 1 MiB preview bound.
- CRC presets: CRC-32/MPEG-2 (project xorout 0xFFFFFFFF, labelled),
  CRC-32/ISO-HDLC (zlib), CRC-16/XMODEM, sum8, over any address range
  with an explicit unmapped-byte policy.
- File open/save through native dialogs plus drag-and-drop; canonical
  serialization on save.
- Bilingual UI (English, 简体中文) with the teaching copy engine-owned
  (中英同源, stable keys).
- Infrastructure first: Ed25519-signed update feed (update-manifest.json
  release asset), three-platform release pipeline with SHA256SUMS and
  build provenance, version-consistency gate, Flatpak bundle manifest.
