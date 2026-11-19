#lang racket/base

;; English strings. Keys are stable identifiers; UI truth = design/prototype/.
;; Explanatory copy is a product asset, not a comment — keep it at teaching
;; quality and mirror every key in zh.rkt.

(provide strings)

(define strings
  (hasheq
   ;; ---- app ----
   'app-name "Bitsmith"
   'tagline "Understand and master firmware images"

   ;; ---- format labels ----
   'format-intel "Intel HEX"
   'format-srec "Motorola S-record"
   'format-bin "Raw BIN"
   'format-elf "ELF"

   ;; ---- operation names / descriptions ----
   'op-fill-name "Fill"
   'op-fill-desc "Materialise a missing range"
   'op-pad-name "Pad to alignment"
   'op-pad-desc "Extend the final segment"
   'op-offset-name "Offset"
   'op-offset-desc "Relocate absolute addresses"
   'op-crop-name "Crop"
   'op-crop-desc "Keep an inclusive address range"
   'op-merge-name "Merge"
   'op-merge-desc "Split at the widest gap and re-place the upper part"
   'op-convert-name "Convert"
   'op-convert-desc "Make the output strategy explicit"
   'op-crc-name "CRC"
   'op-crc-desc "Compute from actual working bytes"
   'op-badge-edit "edit"
   'op-badge-read "read"

   ;; ---- operation field labels ----
   'field-start "Start address"
   'field-end "End address · inclusive"
   'field-value "Fill value"
   'field-alignment "Alignment · bytes"
   'field-delta "Signed offset"
   'field-base "Destination base"
   'field-target "Target format"
   'field-width "S-record address width"
   'field-line "Data bytes per line"
   'field-preset "Preset"
   'field-help "Ranges are inclusive. Preview is bounded to 1 MiB. Apply commits to the working copy."

   ;; ---- operation note keys (preview copy) ----
   'note-fill "Fill the range with the chosen value. Addresses stay absolute; existing bytes inside the range are overwritten."
   'note-pad-aligned "Already aligned; no bytes added."
   'note-pad "Append bytes through the alignment boundary. The pad is data: it is written on save like any other byte."
   'note-offset "Relocate every populated address by the signed delta; payload stays unchanged."
   'note-crop "Keep the range; remove all other populated bytes."
   'note-merge "The image splits at its widest gap: the lower part stays put, the upper part relocates to the destination base. Overlap blocks the apply."
   'note-convert-hex "Working copy stays in Intel HEX. Byte content is unchanged; the output is re-recorded on save with the canonical strategy."
   'note-convert-srec "Working copy stays in S-record with the chosen address width. Sparse ranges remain sparse; gap fill applies only to BIN."
   'note-convert-bin "BIN materialises every hole with the chosen fill value. Address metadata is replaced by the explicit base assumption."

   ;; ---- CRC preset notes ----
   'crc-note-mpeg2 "Automotive project preset · xorout follows the project brief (0xFFFFFFFF). Conventional MPEG-2 uses xorout 0x00000000."
   'crc-note-iso-hdlc "zlib-compatible · reflected input and output."
   'crc-note-xmodem "16-bit result · no reflection."
   'crc-note-sum8 "Add bytes modulo 256; this is an additive checksum."
   'crc-read-only "Read-only · no stored CRC is assumed, no match verdict is claimed."

   ;; ---- option labels ----
   'option-0x00 "0x00"
   'option-0xFF "0xFF"
   'option-reject "Reject gaps"
   'option-hex "HEX"
   'option-srec "SREC"
   'option-bin "BIN"
   'option-s1 "S1"
   'option-s2 "S2"
   'option-s3 "S3"
   'option-line-16 "16"
   'option-line-32 "32"

   ;; ---- errors (keys are stable; text is user-facing) ----
   'err-address-format "Use a decimal number or a hexadecimal number beginning with 0x."
   'err-address-out-of-range "Value is outside the unsigned 32-bit address space."
   'err-start-above-end "Start must be at or below end."
   'err-range-too-large "Keep this operation to 1 MiB or less."
   'err-value-out-of-range "Fill value must be a byte (0x00-0xFF)."
   'err-alignment-invalid "Alignment must be a power of two, from 1 through 1048576."
   'err-empty-image "No image is loaded."
   'err-crop-empty "This crop would produce an empty image. Choose a range containing data."
   'err-merge-two-segments "Merge needs an image with a gap to split at. Use crop and offset to shape the inputs first."
   'err-merge-overlap "Overlap conflict: the relocated part covers existing bytes. Set a non-overlapping destination base."
   'err-relocation-out-of-range "Relocation would leave the unsigned 32-bit address space."
   'err-width-loss "This S-record width cannot encode the highest populated address. Use S3 for 32-bit absolute addresses; no implicit truncation or relocation."
   'err-bin-base-above-start "BIN base must be at or below the first populated address."
   'err-bin-too-large "BIN output exceeds the 1 MiB working limit."
   'err-unknown-op "Unknown operation."
   'err-unknown-preset "Unknown CRC preset."
   'err-crc-unmapped-at "Unmapped byte at the shown address. Select an explicit fill policy or narrow the range."
   'err-not-elf "This file is not an ELF image."
   'err-elf-truncated "ELF header is truncated; the file may be damaged."
   'err-elf-unsupported-class "Unsupported ELF class; the read-only summary covers ELF32 and ELF64."
   'err-elf-unsupported-data "Unsupported ELF endianness; the read-only summary covers little- and big-endian."
   'err-elf-no-sections "This ELF has no section table; the read-only summary needs sections."
   'err-file-too-large "File exceeds the 4 MiB open limit for this preview build."
   'err-unreadable "The file could not be read."
   'err-no-valid-records "No valid records were found. Check that the file is Intel HEX or Motorola S-record and try again."
   'err-revision-conflict "The working copy moved since this preview. Re-run the preview before applying."

   ;; ---- workspace phrases ----
   'phrase-sample-restored "Sample image restored · checksums recomputed"
   'phrase-loaded "Loaded · content detected"
   'phrase-saved "Saved"
   'phrase-save-cancelled "Save cancelled"
   'phrase-open-cancelled "No file chosen"
   'phrase-file-closed "File closed · workspace emptied"
   'phrase-conversion-applied "Format switched · bytes unchanged"
   'phrase-bin-materialised "Gaps materialised with the chosen fill value"
   'phrase-applied "Applied to working copy · revision"

   ;; ---- file dialog ----
   'dialog-open-title "Open firmware image"
   'dialog-save-title "Save firmware image"
   'filter-hex "Intel HEX files"
   'filter-srec "S-record files"
   'filter-bin "Binary files"
   'filter-all "All files"

   ;; ---- record-view phrases (engine-side) ----
   'phrase-verify-copy "Checksums computed from the bytes on every load."
   'phrase-live-verify "Live verification recomputes every record from its bytes. No verdict is hard-coded in the interface."
   'phrase-checksum-mismatch "Checksum mismatch."
   'phrase-checksum-mismatch-detail "The bytes sum to the shown value; two's complement gives the expected byte, but the line stores a different one. The row stays visible so you can decide whether to repair or reject it."
   'phrase-checksum-ok "Checksum verified. The stored check byte matches the computed value."
   'phrase-base-record "This record sets a base. It writes no flash bytes; its payload becomes the upper address bits for the records that follow."

   ;; ---- image-view phrases ----
   'phrase-bin-banner "BIN carries no address information — the base below is an assumption you set"
   'phrase-bin-banner-detail "No address records were found. Bitsmith is displaying the bytes at the working base. Check this base against the device memory map before writing."
   'phrase-hex-basis-hex "The displayed addresses come from the file's records. No base assumption is needed."
   'phrase-hex-basis-bin "A BIN has no address records. This session treats the first byte as the working base; every address inherits that assumption."

   ;; ---- learn view (engine-verified arithmetic) ----
   'learn-intel-step-1 "Sum bytes"
   'learn-intel-step-1-note "Count, address, and data; Intel HEX also includes type."
   'learn-intel-step-2 "Low byte"
   'learn-intel-step-2-note "Discard carries above eight bits."
   'learn-intel-step-3 "Two's complement"
   'learn-intel-step-3-note "100 minus the low byte, masked to eight bits."
   'learn-intel-step-4 "Compare"
   'learn-intel-step-4-note "Stored versus computed."
   'learn-srec-step-3 "One's complement"
   'learn-srec-step-3-note "FF minus the low byte, masked to eight bits."
   'learn-input-error "Enter a colon followed by complete hexadecimal byte pairs (count, address, type, data, checksum)."
   'learn-count-mismatch "Count mismatch: count declares the shown number of data bytes; the line contains a different count."
   'learn-pass "PASS · checksum computed from the current input."
   'learn-fail "FAIL · stored value differs from the computed one. Input is preserved; no repair is applied."

   ;; ---- save format chooser ----
   'save-format "Format"
   'save-format-current "Current format"))
