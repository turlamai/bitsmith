# Exit conditions

1. [ ] All four screens are complete: Records, Image, Operations, Format reference. Sources exist; final user acceptance remains open.
2. [ ] Interaction logic is frozen: hover-explain, edit-preview, convert-strategy. The implemented baseline is described below; freezing requires user acceptance.
3. [ ] HIG checklist passes: content first, direct manipulation, immediate feedback, error prevention, keyboard access, non-color feedback, consistent navigation. Final review remains open.
4. [ ] User is satisfied. Only the user can close this condition.

# Bitsmith design contract

## Brief

Project identifier: `bitsmith`. Brand in prose: **Bitsmith**. A local firmware-image workbench for embedded and FBL developers, built on a Racket engine and system WebView through glaze. The prototype is the editable first UI baseline, not a marketing site. Product business logic belongs in the Racket engine; the local JavaScript here demonstrates the interaction contract for later typed RPC integration.

Entry: `index.html`. Screens: `prototype/records.html`, `prototype/image.html`, `prototype/operations.html`, `prototype/learn.html`. Shared visual source: `prototype/shared.css`. No external fonts, CDN, assets or build step.

## Design principles

- **Content first:** absolute addresses, bytes, checksum arithmetic and affected ranges lead. Graphite workbench surfaces, one-pixel structural rules and restrained blue/teal accents continue the approved engineering console.
- **Direct manipulation:** select records and bytes; edit explicitly labelled operation parameters. Data and chrome use system monospace and system sans respectively.
- **Immediate feedback:** edits recompute previews and CRC values locally. Verdicts are derived from arithmetic and never inferred from a static success label.
- **Error prevention:** every edit previews its effect. Apply opens a confirmation with exact byte-change counts; invalid addresses, width loss and merge overlaps block Apply. No source file is overwritten.
- **Consistency:** Records, Image and shared.css retain their existing approved styles. The two remaining workbench screens compose their existing classes and tokens. Desktop target is 1280–1600 px, with a 1024 px working layout.

## Design tokens — exact semantic pairs

The table is transcribed from the existing stylesheet. Dark is default. A repeated light value inherits the shared declaration. No additional token names are introduced. Surface/text, accent/contrast, status/status-background and region/region-background pairs retain the same semantics in both themes.

| Token | Dark | Light |
| --- | --- | --- |
| `--bg` | `#0a0e13` | `#edf1f5` |
| `--bg-alt` | `#0e141b` | `#f5f7f9` |
| `--surface-1` | `#111820` | `#ffffff` |
| `--surface-2` | `#151d27` | `#f3f6f9` |
| `--surface-3` | `#1a2430` | `#eaf0f6` |
| `--bg-selected` | `#14293a` | `#dceefc` |
| `--inset` | `#0b1017` | `#e9eef4` |
| `--border` | `#25313e` | `#d7e0e9` |
| `--border-strong` | `#36485c` | `#b9c6d4` |
| `--text` | `#e7edf5` | `#16212c` |
| `--muted` | `#99a8ba` | `#536273` |
| `--faint` | `#6a7a8e` | `#7b8897` |
| `--accent` | `#66b8ff` | `#0b67ae` |
| `--accent-2` | `#5ad1b6` | `#0b7b6b` |
| `--accent-contrast` | `#06131d` | `#ffffff` |
| `--ok` | `#58ca8b` | `#1e7c50` |
| `--ok-bg` | `#10251b` | `#e5f5ec` |
| `--warn` | `#e7ad4c` | `#8b5b0b` |
| `--warn-bg` | `#2a2113` | `#f9efd9` |
| `--fail` | `#f07070` | `#b23a3f` |
| `--fail-bg` | `#2a1517` | `#fbe8e9` |
| `--fbl` | `#64b5f6` | `#1768ad` |
| `--fbl-bg` | `#102436` | `#e2effa` |
| `--app` | `#4ecdb0` | `#11766a` |
| `--app-bg` | `#0f2723` | `#e1f3f0` |
| `--gap` | `#738399` | `#68798a` |
| `--gap-bg` | `#161d26` | `#edf1f5` |
| `--ff` | `#b9a0ff` | `#6f4bb5` |
| `--ff-bg` | `#201a33` | `#efe9fb` |
| `--focus-ring` | `#a9d8ff` | `#0b67ae` |
| `--topbar` | `#0d1218` | `#ffffff` |
| `--statusbar` | `#0c1117` | `#f5f8fb` |
| `--shadow` | `0 18px 60px rgba(0, 0, 0, 0.45)` | `0 22px 60px rgba(24, 42, 62, 0.14)` |
| `--shadow-sm` | `0 2px 10px rgba(0, 0, 0, 0.25)` | `0 2px 10px rgba(24, 42, 62, 0.08)` |
| `--scrollbar` | `#344355` | `#b9c6d4` |
| `--font-sans` | `-apple-system, BlinkMacSystemFont, "Segoe UI", "Helvetica Neue", Arial, sans-serif` | `-apple-system, BlinkMacSystemFont, "Segoe UI", "Helvetica Neue", Arial, sans-serif` |
| `--font-mono` | `"SFMono-Regular", "SF Mono", ui-monospace, Menlo, Consolas, "Liberation Mono", monospace` | `"SFMono-Regular", "SF Mono", ui-monospace, Menlo, Consolas, "Liberation Mono", monospace` |
| `--text-2xs` | `10px` | `10px` |
| `--text-xs` | `11px` | `11px` |
| `--text-sm` | `12px` | `12px` |
| `--text-base` | `13px` | `13px` |
| `--text-md` | `14px` | `14px` |
| `--text-lg` | `16px` | `16px` |
| `--text-xl` | `20px` | `20px` |
| `--text-2xl` | `26px` | `26px` |
| `--text-3xl` | `34px` | `34px` |
| `--lh-tight` | `1.25` | `1.25` |
| `--lh-normal` | `1.5` | `1.5` |
| `--lh-relaxed` | `1.65` | `1.65` |
| `--space-1` | `4px` | `4px` |
| `--space-2` | `8px` | `8px` |
| `--space-3` | `12px` | `12px` |
| `--space-4` | `16px` | `16px` |
| `--space-5` | `20px` | `20px` |
| `--space-6` | `24px` | `24px` |
| `--space-7` | `32px` | `32px` |
| `--space-8` | `40px` | `40px` |
| `--space-9` | `48px` | `48px` |
| `--radius-xs` | `3px` | `3px` |
| `--radius-sm` | `5px` | `5px` |
| `--radius-md` | `8px` | `8px` |
| `--radius-pill` | `999px` | `999px` |
| `--topbar-h` | `52px` | `52px` |
| `--statusbar-h` | `30px` | `30px` |
| `--sidebar-w` | `282px` | `282px` |
| `--inspector-w` | `302px` | `302px` |
| `--ease-out` | `cubic-bezier(0.18, 0.72, 0.24, 1)` | `cubic-bezier(0.18, 0.72, 0.24, 1)` |
| `--ease-in` | `cubic-bezier(0.55, 0, 0.8, 0.35)` | `cubic-bezier(0.55, 0, 0.8, 0.35)` |
| `--dur-fast` | `160ms` | `160ms` |
| `--dur-normal` | `220ms` | `220ms` |

Semantic roles: `--bg`/`--text` form the canvas pair; `--surface-1/2/3` and `--inset` form the workbench hierarchy; `--muted` is secondary text; `--faint` is tertiary chrome. `--accent` pairs with `--accent-contrast`. `--ok`, `--warn`, `--fail`, `--fbl`, `--app`, `--gap` and `--ff` pair with their corresponding `-bg` tokens. Color always accompanies a text label or structure. Existing compact type sizes are deliberately retained from the approved baseline rather than substituted with a new type scale.

## Component vocabulary

| Component | Contract |
| --- | --- |
| Record table | Count, type, absolute address, payload, stored checksum, computed checksum, verdict; selection drives inspector. |
| Segment map | Populated ranges and unmapped gaps remain distinct. Operation before/after maps use one shared linear address scale. Small segments may have a minimum visible mark. |
| Hex grid | Address-labelled byte cells and selected-byte state; never silently materialise gaps. |
| Explain popover | Field role and arithmetic, available on hover and keyboard/click; Escape dismisses and focus returns. |
| Inspector | Selected-item details or Apply gate; secondary to the central task. |
| Operation card | Parameters → before/after map → affected-byte and record summary → confirmation → local commit. |
| Status bar | Current state and revision; derived from the same local state as the view. |
| Assumption banner | Marks BIN base and any substituted gap fill explicitly. |

## Interaction baseline

- **Hover-explain:** existing record explain popovers stay intact; teaching bytes expose field labels on hover and keyboard focus.
- **Edit-preview:** Fill, Pad to alignment, Offset, Crop, Merge, Convert and CRC have live parameter-driven previews. Changes report additions, removals and modified bytes with a bounded first-12-byte diff. Before/after canonical HEX record counts are computed; source text remains unchanged. Canonical records are newly generated output previews and may differ from the supplied line grouping.
- **Apply:** confirmation snapshots the preview and revision. Commit updates the current page's byte map, format, map, totals and gate. Reset restores the supplied sample. No write-back to disk or cross-view session sharing is claimed.
- **Merge:** source segments are the supplied FBL and APP. Separate placement succeeds; “Overlap FBL · error” demonstrates a blocked collision. Resolve through an explicit non-overlapping APP base; never silently overwrite.
- **Convert strategy:** HEX/SREC/BIN target, S1/S2/S3 address width, 16/32 data bytes per line, 0x00/0xFF gap fill, BIN base. Width loss blocks conversion; S3 is needed for the supplied 32-bit absolute addresses. Sparse text output retains gaps. BIN materialises gaps and carries an explicit base assumption. No download/export is added.
- **CRC:** reads current populated bytes plus the explicit missing-byte policy over an inclusive range. MPEG-2 project preset uses the requested poly 0x04C11DB7, init 0xFFFFFFFF, xorout 0xFFFFFFFF, no reflection. This differs from conventional MPEG-2 xorout 0x00000000 and is labelled in the UI. ISO-HDLC uses zlib-compatible reflection; XMODEM and sum8 are available. There is no invented stored CRC or match verdict.
- **Teaching:** byte-by-byte Intel HEX and S7 termination anatomy; live HEX input arithmetic and computed S-record one's-complement arithmetic; comparison covers addresses, overhead, use and risk. Supplied source samples are preserved verbatim in a disclosure.

## Invariants

- **Checksum verdicts computed live, never static.** Preserve original records even when arithmetic disagrees; never silently repair them.
- **Addresses always absolute.** Raw record-relative address fields in anatomy are explicitly labelled and resolved with their address-extension record.
- A gap is missing information, not 0xFF. Fill policy is always explicit.
- FBL ends at 0x0800001F; APP starts at 0x08008000; the gap is 0x7FE0 bytes. The APP base offset is 0x8000.
- Stored and expected checksum bytes are separate values. The deliberately corrupted `:0480200048B1084700` is preserved; expected checksum is computed as 14.
- All supplied source strings remain unchanged. Local operations use decoded byte maps; overlapping source addresses take the last supplied record's byte for this bounded preview.
- Preview and CRC range processing is bounded to 1 MiB; address arithmetic is unsigned 32-bit. No large-file performance claim.

## HIG checklist for acceptance

- [ ] Content hierarchy exposes address basis, selection and result state.
- [ ] All edit paths preview before confirmation; invalid operations explain a remedy.
- [ ] Keyboard navigation, visible focus, labels and Escape paths are usable.
- [ ] Dark and light themes retain readable contrast and non-color verdicts.
- [ ] 1024–1600 px desktop layouts keep core actions reachable; narrower layouts retain an operation selector.
- [ ] Reduced-motion preferences and system typography are respected.
- [ ] User confirms hover-explain, edit-preview and convert-strategy behavior.

No new screenshot, browser review or acceptance run is claimed for this completion pass.

## Platform differences

Interaction logic, terminology, selection and operation flow are identical on macOS, Windows and Linux. Platform mechanisms follow the native host: Command-based shortcuts on macOS and Control-based equivalents on Windows/Linux, native menus, window controls, file dialogs and focus conventions. Browser prototype shortcuts 1–4 navigate views and do not fire while editing fields. Native host window chrome is supplied by each platform, not simulated in this HTML.

Professional firmware tooling targets desktop macOS/Windows/Linux; no mobile product roadmap is added.

## Out of scope — phase 2

Header templates, vector table tooling, and a dedicated image-to-image diff workspace belong to phase 2. The required operation preview diff remains in scope. Native RPC integration, production file writing, shared multi-view sessions, large-file processing, persistence across reloads and standalone export are not represented as implemented engine features.


## 2026-11-15 navigation repair

The root entry opens `prototype/records.html` directly. The previous screen overview is removed. The Operations conversion preview executes after repairing its newline literal; existing arithmetic and confirmation gates are unchanged. Final design acceptance remains open.


## Prototype source checkpoint — 2026-11-15

`index.html` opens the primary prototype directly. Screen-directory launchers have been removed. All local scripts, styles and referenced assets needed by this checkpoint are versioned under this directory; OpenDesign metadata is excluded. This is an editable prototype checkpoint, not a claim that the native product or external services implement these interactions.
