# Exit conditions

1. [ ] All four screens are complete: Records, Image, Operations, Format reference. Sources exist; final user acceptance remains open.
2. [ ] Interaction logic is frozen: hover-explain, edit-preview, convert-strategy. The implemented baseline is described below; freezing requires user acceptance.
3. [ ] HIG checklist passes: content first, direct manipulation, immediate feedback, error prevention, keyboard access, non-color feedback, consistent navigation. Final review remains open.
4. [ ] User is satisfied. Only the user can close this condition.

# bitsmith design contract

## Brief

Project identifier: `bitsmith`. Brand in prose: **bitsmith**. A local firmware-image workbench for embedded and FBL developers, built on a Racket engine and system WebView through glaze. The prototype is the editable first UI baseline, not a marketing site. Product business logic belongs in the Racket engine; the local JavaScript here demonstrates the interaction contract for later typed RPC integration.

Entry: `index.html`. Screens: `prototype/records.html`, `prototype/image.html`, `prototype/operations.html`, `prototype/learn.html`. Shared visual source: `prototype/shared.css`. No external fonts, CDN, assets or build step.

## Design principles

- **Content first:** absolute addresses, bytes, checksum arithmetic and affected ranges lead. Graphite workbench surfaces, one-pixel structural rules and restrained blue/teal accents continue the approved engineering console.
- **Direct manipulation:** select records and bytes; edit explicitly labelled operation parameters. Data and chrome use system monospace and system sans respectively.
- **Immediate feedback:** edits recompute previews and CRC values locally. Verdicts are derived from arithmetic and never inferred from a static success label.
- **Error prevention:** every edit previews its effect. Apply opens a confirmation with exact byte-change counts; invalid addresses, width loss and merge overlaps block Apply. No source file is overwritten.
- **Consistency:** The four screens use the 2026-11-20-minimal-family roles and one shared token source. Functional graphics and existing interaction contracts are retained. Desktop target is 1280–1600 px, with a 1024 px working layout.

## Family alignment — 2026-11-22

Owner requirement: align Bitsmith with **2026-11-20-minimal-family** while retaining the graphite engineering workbench, glaze UI, English copy and all firmware sample bytes.

- Sub-12px text declarations and font tokens are removed. **Exceptions: none.** Interface roles are 12 / 13 / 14 / 18 / 24px; data/address/byte annotations are at least 12px in the system monospace role.
- Spacing uses 4 / 8 / 12 / 16 / 24 / 32 / 48px. Corner roles: inset 4px, control 8px, panel 12px. Hairlines and baseline/icon geometry are not spacing roles.
- Graphite dark is the default; the independently authored light theme uses the same semantic roles. Both themes cover canvas, surfaces, text, supporting text, borders, accent and foreground, selection, focus, success, warning, error and data-region colors.
- The existing theme button is rendered as a monochrome ◐ icon button with an accessible target-theme name, pressed state, keyboard focus and existing local theme preference.
- Hatch, byte-grid graphics, hairline rules and check marks are functional content and remain. No decorative gradients, glass or glow are introduced.
- At 1024–1320px the inspector moves below the main pane, preserving access rather than shrinking text. Data tables and byte grids have intentional internal scrolling; page chrome must not clip. At wider desktop sizes the three-column workbench remains.
- Source checkpoint: no git metadata is present in this OpenDesign project, so a starting commit SHA is unavailable.

### Slice exit conditions

- [x] Source scan: no declared font size or font-size token below 12px on any of the four screens. Rendered text inspection remains unverified.
- [x] Both theme palettes and the shared switch implementation are present. The 84 declared normal-text/semantic-background pairings checked exceed 4.5:1; runtime switch and composited-state inspection remain unverified.
- [ ] Four screens checked at 1024, 1280 and 1600px with no unintended clipping, overlap or broken wrapping.
- [x] No external resource references or missing local links were found. Functional hatch declarations remain. Supplied sample records are retained; business-handler syntax passes, while runtime interaction checks remain unverified.
- [x] This English contract and exact semantic pairs match the implemented base-theme revision; responsive inspector placement is documented separately.

## Design tokens — exact semantic pairs

The table is transcribed from the existing stylesheet. Dark is default. A repeated light value inherits the shared declaration. No additional token names are introduced. Surface/text, accent/contrast, status/status-background and region/region-background pairs retain the same semantics in both themes.

| Token | Dark | Light |
| --- | --- | --- |
| `--bg` | `#141414` | `#f2f2f2` |
| `--bg-alt` | `#181818` | `#fafafa` |
| `--surface-1` | `#1c1c1c` | `#ffffff` |
| `--surface-2` | `#242424` | `#f5f5f5` |
| `--surface-3` | `#2c2c2c` | `#ebebeb` |
| `--bg-selected` | `#19364b` | `#daeafa` |
| `--inset` | `#101010` | `#ededed` |
| `--border` | `#454545` | `#cdcdcd` |
| `--border-strong` | `#808080` | `#777777` |
| `--text` | `#eeeeee` | `#202020` |
| `--muted` | `#b8b8b8` | `#505050` |
| `--faint` | `#a6a6a6` | `#595959` |
| `--accent` | `#80c6ff` | `#075f9b` |
| `--accent-2` | `#80c6ff` | `#075f9b` |
| `--accent-contrast` | `#10202c` | `#ffffff` |
| `--ok` | `#8cdbac` | `#19643c` |
| `--ok-bg` | `#172d21` | `#e4f4e9` |
| `--warn` | `#f4cc80` | `#754800` |
| `--warn-bg` | `#322816` | `#fbefd5` |
| `--fail` | `#ffaaaa` | `#a52c37` |
| `--fail-bg` | `#351e22` | `#fbe8eb` |
| `--fbl` | `#80c6ff` | `#075f9b` |
| `--fbl-bg` | `#193044` | `#e0edfa` |
| `--app` | `#80d8c0` | `#086453` |
| `--app-bg` | `#17332b` | `#e1f3ec` |
| `--gap` | `#a6a6a6` | `#595959` |
| `--gap-bg` | `#222222` | `#ededed` |
| `--ff` | `#cbb2ff` | `#653a9c` |
| `--ff-bg` | `#30263f` | `#efe7fa` |
| `--focus-ring` | `#b1daff` | `#075f9b` |
| `--topbar` | `#181818` | `#ffffff` |
| `--statusbar` | `#181818` | `#f5f5f5` |
| `--shadow` | `0 18px 60px rgba(0, 0, 0, 0.45)` | `0 22px 60px rgba(24, 42, 62, 0.14)` |
| `--shadow-sm` | `0 2px 10px rgba(0, 0, 0, 0.25)` | `0 2px 10px rgba(24, 42, 62, 0.08)` |
| `--scrollbar` | `#808080` | `#777777` |
| `--font-sans` | `system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", "PingFang SC", "Microsoft YaHei", "Noto Sans CJK SC", sans-serif` | `system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", "PingFang SC", "Microsoft YaHei", "Noto Sans CJK SC", sans-serif` |
| `--font-mono` | `ui-monospace, "SFMono-Regular", Consolas, "Liberation Mono", monospace` | `ui-monospace, "SFMono-Regular", Consolas, "Liberation Mono", monospace` |
| `--text-2xs` | `12px` | `12px` |
| `--text-xs` | `12px` | `12px` |
| `--text-sm` | `13px` | `13px` |
| `--text-base` | `14px` | `14px` |
| `--text-md` | `14px` | `14px` |
| `--text-lg` | `18px` | `18px` |
| `--text-xl` | `24px` | `24px` |
| `--text-2xl` | `24px` | `24px` |
| `--text-3xl` | `24px` | `24px` |
| `--lh-tight` | `1.25` | `1.25` |
| `--lh-normal` | `1.5` | `1.5` |
| `--lh-relaxed` | `1.65` | `1.65` |
| `--space-1` | `4px` | `4px` |
| `--space-2` | `8px` | `8px` |
| `--space-3` | `12px` | `12px` |
| `--space-4` | `16px` | `16px` |
| `--space-5` | `24px` | `24px` |
| `--space-6` | `24px` | `24px` |
| `--space-7` | `32px` | `32px` |
| `--space-8` | `32px` | `32px` |
| `--space-9` | `48px` | `48px` |
| `--radius-xs` | `4px` | `4px` |
| `--radius-sm` | `8px` | `8px` |
| `--radius-md` | `12px` | `12px` |
| `--radius-pill` | `999px` | `999px` |
| `--topbar-h` | `64px` | `64px` |
| `--statusbar-h` | `40px` | `40px` |
| `--sidebar-w` | `264px` | `264px` |
| `--inspector-w` | `288px` | `288px` |
| `--ease-out` | `cubic-bezier(0.18, 0.72, 0.24, 1)` | `cubic-bezier(0.18, 0.72, 0.24, 1)` |
| `--ease-in` | `cubic-bezier(0.55, 0, 0.8, 0.35)` | `cubic-bezier(0.55, 0, 0.8, 0.35)` |
| `--dur-fast` | `160ms` | `160ms` |
| `--dur-normal` | `220ms` | `220ms` |

Semantic roles: `--bg`/`--text` form the canvas pair; `--surface-1/2/3` and `--inset` form the workbench hierarchy; `--muted` is secondary text; `--faint` is tertiary chrome. `--accent` pairs with `--accent-contrast`. `--ok`, `--warn`, `--fail`, `--fbl`, `--app`, `--gap` and `--ff` pair with their corresponding `-bg` tokens. Color always accompanies a text label or structure. The family font-size floor is 12px, with no exceptions. Auxiliary text and data annotations use 12px, labels use 13px, UI body uses 14px, group headings use 18px and page headings use 24px. Data stays in the system monospace role; UI prose uses the system UI stack.

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
- **Edit-preview:** Fill, Patch, Pad to alignment, Offset, Crop, Merge, Convert and CRC have live parameter-driven previews. Changes report additions, removals and modified bytes with a bounded first-12-byte diff. Before/after canonical HEX record counts are computed; source text remains unchanged. Canonical records are newly generated output previews and may differ from the supplied line grouping.
- **Patch:** an absolute address plus hexadecimal byte pairs (`48 B1 08 47` or `48B10847`; separators and `0x` prefixes are optional). Bytes overwrite populated data. A byte that lands in an unmapped range is new data: it is counted as added, marked `+` in the diff and named in the preview note — a gap is never treated as `0xFF`. A patch whose bytes are already present blocks Apply. `operations.html#<operation-id>` opens a card directly and the hash follows the selection, so a card can be reached by link and by the acceptance script.
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

The 2026-11-22 family-alignment checks are recorded below after implementation; earlier checkpoints do not imply acceptance of this revision.

## Platform differences

Interaction logic, terminology, selection and operation flow are identical on macOS, Windows and Linux. Platform mechanisms follow the native host: Command-based shortcuts on macOS and Control-based equivalents on Windows/Linux, native menus, window controls, file dialogs and focus conventions. Browser prototype shortcuts 1–4 navigate views and do not fire while editing fields. Native host window chrome is supplied by each platform, not simulated in this HTML.

Professional firmware tooling targets desktop macOS/Windows/Linux; no mobile product roadmap is added.

## Out of scope — phase 2

Header templates, vector table tooling, and a dedicated image-to-image diff workspace belong to phase 2. The required operation preview diff remains in scope. Starting a patch from a byte selection in the Image view, and marking source records that no longer match the working copy after a patch, are not designed yet. Native RPC integration, production file writing, shared multi-view sessions, large-file processing, persistence across reloads and standalone export are not represented as implemented engine features.


## 2026-11-15 navigation repair

The root entry opens `prototype/records.html` directly. The previous screen overview is removed. The Operations conversion preview executes after repairing its newline literal; existing arithmetic and confirmation gates are unchanged. Final design acceptance remains open.


## Prototype source checkpoint — 2026-11-15

`index.html` opens the primary prototype directly. Screen-directory launchers have been removed. All local scripts, styles and referenced assets needed by this checkpoint are versioned under this directory; OpenDesign metadata is excluded. This is an editable prototype checkpoint, not a claim that the native product or external services implement these interactions.


## Family-alignment self-check — 2026-11-22

Implemented files: `prototype/shared.css` and all four screen HTML files; this contract was updated before prototype styles. Root navigation and firmware sample content were not redesigned.

| Check | Result | Evidence / limit |
| --- | --- | --- |
| Font-size floor | Source passed | Zero sub-12px declarations across shared.css and four screens; all nine existing font-size tokens resolve to 12 / 13 / 14 / 18 / 24px. Runtime/browser-default text is not measured. |
| Semantic contrast | Numerical passed | 42 pairings per theme: primary/supporting/faint/accent/gap text against seven neutral/selection surfaces, six status/data pairs, and the accent foreground pair. Minimum dark 5.16:1; minimum light 5.49:1. Gradients, compositing, hover/focus rendering and the full rendered DOM were not measured. |
| Functional graphics | Source passed | Four repeating-linear-gradient declarations retained in shared.css, plus the existing page-level gap swatch; hairline rules and check marks retained. |
| Theme mechanism | Implemented; runtime unverified | Existing preference and event handlers retained; four buttons share ◐ appearance, target-theme label, pressed state and focus styling. |
| JavaScript syntax | Passed | All 12 inline scripts parse with Node. This is not a runtime interaction test. |
| Dependencies and links | Source passed | No remote script/style/image/font references or imports; local href/src targets resolve. |
| Sample content | Retained | The known corrupted HEX line and S7 termination record remain verbatim; edits target font declarations, spacing, color tokens and theme accessibility rather than firmware data. |
| 1024 / 1280 / 1600px layout | Unverified in actual rendering | Responsive source reflows the inspector below the main pane through 1320px; tables/hex grids scroll internally; map annotations are in normal flow. Browser launch aborted before any page loaded, so no viewport, overlap or clipping result is claimed. |
| Native Glaze and other OS | Unverified | No macOS/Windows/Linux native host inspection, screen-reader pass, system text scaling or 200% zoom check was performed. |

### Verification constraint

The installed headless browser exited during launch (SIGABRT); the browser-access host was unavailable, and native OpenDesign preview access was not approved. No screenshots were captured and no theme-click or operation-flow test completed in this pass. These are concrete verification gaps, not evidence that the layouts pass. The layout exit condition and final user acceptance remain open.


## Patch operation — 2026-11-25

Added prototype-first (issue #5): a Patch card on the Operations screen, second in the list after Fill. Contract is the Patch bullet under Interaction baseline. No new token, component or layout was introduced; the card reuses the operation form, and the byte field is a plain text input with an example placeholder.

| Check | Result | Evidence / limit |
| --- | --- | --- |
| Prototype script syntax | Passed | All inline scripts on `prototype/operations.html` parse with Node 22. |
| Prototype patch logic | Passed in a stubbed DOM | Default patch (`0x08008010` ← `00 BF`) changes 2 bytes; bytes landing in a hole are reported as added; identical bytes, malformed pairs, empty input and address overflow each block with a specific message. Not a browser rendering test. |
| Product implementation | Passed on Windows | Rendered in the real WebView (2000×1100 window at 150%, about 1300 CSS px): Patch card from `api/ops/specs`, diff reports 2 changed bytes, gate ready, zh copy intact. Screenshots stay outside the repo (the CLI cannot attach images to issues). macOS and Linux WebView rendering not inspected. |
| Operation-list grid | Fixed in prototype and product | The native screenshot showed card names wrapping two characters per line: `.op-item` reserved a 26px icon column that the markup no longer fills, so the name landed in it. The template is now `minmax(0, 1fr) auto`, re-checked in both renderings on Windows. |
| Top-bar operation count | Fixed | The badge was typed as "7 operations"; it now follows the engine's card list and is localized. |
| Known gap left open | Open | `public/shared.css` does not yet carry the responsive rules and 12px type floor of design pass `f9fe410`: at the same width the product keeps three columns where the prototype moves the inspector below the main pane. A separate alignment slice, not part of the Patch change. |
| User acceptance | Open | Only the user can close this condition. |
