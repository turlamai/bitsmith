# Binlet Product Spec

Single source of truth for scope and product decisions. UI truth lives in
`design/prototype/`; engine truth lives in `shared/engine/`.

## Positioning

A local firmware-image workbench: turn Intel HEX / Motorola S-record / raw BIN
into a memory image you can **understand, edit and transform** — record-level
explanations, semantic editing with checksum recalculation, and the operations
FBL developers do daily (fill, offset, crop, merge, convert, CRC).

- Audience: automotive embedded / FBL developers. Built for personal use
  first, to commercial product standard (family policy).
- Platforms: macOS / Windows / Linux desktop, equal footing. No mobile
  roadmap (professional/hardware class).
- Local-only by design: firmware confidentiality is a red line, not a
  limitation.

## MVP scope (confirmed)

1. **Understand** — content sniffing (extension lies: extensionless ELF files
   are real), record view with per-field teaching explanations (why record
   type 04 exists, when S1/S2/S3), live checksum verification with the math
   shown, image view: address-true hex dump + segment map (segments, gaps,
   overlaps, explicit 0xFF regions), explicit base-address assumption banner
   for BIN.
2. **Edit** (semantic layer; checksums and record structure recalculated):
   patch at address, gap fill / flash-alignment pad, offset (relocate),
   crop address range, merge multiple images (FBL+APP), format conversion
   with configurable strategy (S1/S2/S3, line length, fill value, BIN base).
3. **Compute** — CRC/checksum over any address range. Presets must include:
   CRC-32/MPEG-2 (poly 0x04C11DB7, init 0xFFFFFFFF, xorout 0xFFFFFFFF,
   no reflection — automotive), CRC-32/ISO-HDLC (zlib), CRC-16/XMODEM,
   simple sum8.

## Phase 2 (confirmed out of MVP)

App header templates (custom magic/version/length/CRC layout: generate +
validate), Cortex-M vector table parsing (SP/reset), two-image diff,
batch recipes / CI.

## Format matrix

| Format | MVP | Notes |
|---|---|---|
| Intel HEX | read + write + edit | record types 00/01/02/03/04/05 |
| Motorola S-record | read + write + edit | S0/S1/S2/S3/S5/S7/S8/S9; CRLF+LF |
| raw BIN | read + write | base address is an assumption, surface it |
| ELF / AXF | read-only summary | sections, entry point; AXF is ELF |
| MAP (linker) | roadmap | feeds the segment map with ground truth |
| A2L | out | calibration territory, not our lane |

## Decision log

- 2026-11-13 line: **glaze** (dense table/visualization resident UI; prototype
  doubles as first product UI). rivet rejected for cost on this UI class.
- 2026-11-18 name: **Binlet** — concise product brand for firmware image editing;
  supersedes the previous ImageBench decision. Avoids names already used by
  existing hex-editor projects; keep the GitHub slug until administrative rename.
- 2026-11-13 previous name: **ImageBench** (HexView taken by an existing
  commercial tool; FlashForge collides with a 3D printer brand).
- 2026-11-13 header templates + diff → phase 2.
- 2026-11-13 repo private until first release (family convention: public at
  release time).
- 2026-11-13 family synergy: flashpilot already embeds Intel HEX / S-record /
  BIN models — extracting a shared family parsing library is the preferred
  path when implementation starts (check catalog first).

## Sample-data policy

Samples embedded in prototypes, tests and docs are **synthetic** and every
checksum must verify. Zero company/project information enters this repo
(family policy on employer material: standard-layer format knowledge only).

Verified sample set (round-trip checked):

Intel HEX — FBL@0x08000000, APP@0x08008000, gap between:

```
:020000040800F2
:200000000010020009590108FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7B
:10001000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0
:088000000050002001598A081C
:088010002DE9F0470DF080F8A6
:109FF000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF71
:00000001FF
```

Corrupted record for error-state UI (valid checksum is `14`):

```
:0480200048B1084700
```

Motorola S-record — APP@0x00400000:

```
S0120000496D61676542656E63682D44454D4FD8
S31D004000000050002001598A08FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF56
S31D004000182DE9F0470DF080F800000000000000000000000000000000C8
S3150054FFF0FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFB7
S70500000000FA
```

## Real-world grounding (format-level facts only)

- Extensionless firmware files happen; content sniffing is mandatory.
- S3 (32-bit addressing) common; termination S7/S8/S9 by address width.
- Flash drivers may live at high RAM addresses (downloaded for flashing).
- Erased flash (0xFF) can appear explicitly in files — no gaps, but huge
  0xFF ranges; image view must distinguish gap vs explicit 0xFF.
- CRLF line endings in the wild; parsers accept CRLF and LF.
- MAP files are the layout ground truth users already have.
