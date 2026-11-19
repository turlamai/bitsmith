#lang racket/base

;; Operations and serialization tests, anchored on the verified sample
;; (shared/spec.md): FBL@0x08000000 (32 B incl. overlapping 0xFF tail),
;; APP area from 0x08008000, explicit 0xFF at 0x08009FF0.

(require rackunit
         racket/list
         racket/string
         "crc.rkt"
         "hex.rkt"
         "srec.rkt"
         "image.rkt"
         "ops.rkt"
         "serialize.rkt")

;; Small-image helper for negative tests: runs are (start byte ...).
(define (mkimg . runs)
  (foldl (lambda (run acc)
           (image-set-run acc (car run) (apply bytes (cdr run))))
         empty-image runs))

;; ---- load the sample into an image (ok data records, last-wins) -----------

(define sample-text
  (string-append
   ":020000040800F2\n"
   ":200000000010020009590108FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7B\n"
   ":10001000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0\n"
   ":088000000050002001598A081C\n"
   ":088010002DE9F0470DF080F8A6\n"
   ":109FF000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF71\n"
   ":0480200048B1084700\n"
   ":00000001FF\n"))

(define (load-sample)
  (for/fold ([img empty-image])
            ([record (in-list (parse-intel-hex sample-text))]
             #:when (and (hash-ref record 'ok) (equal? (hash-ref record 'type) 0)))
    (define data (list->bytes (hash-ref record 'data)))
    (image-set-run img (hash-ref record 'absolute) data)))

(define img (load-sample))

;; Unique populated bytes: 32 FBL (the overlapping 0xFF record resolves
;; last-wins) + 8 + 8 + 16 tail = 64. The record-sum figure (84 B) is a
;; per-record stat the API layer reports separately.
(check-equal? (image-total img) 64)
(check-equal? (length (image-ranges img)) 4) ; FBL, APP head, APP mid, FF tail

;; ---- canonical serialization round-trip ------------------------------------

;; Regenerating Intel HEX from the sample image must reproduce every
;; populated byte (line grouping may differ — canonical records are newly
;; generated output, per the design contract).
(define canonical (image->intel-lines img))
(define canonical-img
  (for/fold ([acc empty-image])
            ([record (in-list (parse-intel-hex (string-join canonical "\n")))]
             #:when (and (hash-ref record 'ok) (equal? (hash-ref record 'type) 0)))
    (image-set-run acc
                   (hash-ref record 'absolute)
                   (list->bytes (hash-ref record 'data)))))
(check-equal? (image-ranges canonical-img) (image-ranges img))
(check-equal? (image-total canonical-img) (image-total img))
(for ([range (in-list (image-ranges img))])
  (for ([addr (in-range (car range) (add1 (cdr range)))])
    (check-equal? (image-ref canonical-img addr) (image-ref img addr))))

;; Generated lines carry valid checksums by construction.
(for ([line (in-list canonical)])
  (check-equal? (hash-ref (car (parse-intel-hex line)) 'malformed) #f))

;; S-record canonical output parses back; S1 width loss is the caller's
;; gate (widths below S3 cannot reach 0x08008000+).
(define srec-lines (image->srec-lines img 'S3 16))
(for ([line (in-list srec-lines)])
  (check-equal? (hash-ref (car (parse-srec line)) 'ok) #t))
(check-equal? (last srec-lines) "S70500000000FA")

;; ---- fill ------------------------------------------------------------------

;; Fill the FBL/APP gap with 0xFF: 0x7FE0 bytes added.
(define gap (car (image-gaps img)))
(check-equal? (hash-ref gap 'start) 134217760) ; 0x08000020
(check-equal? (hash-ref gap 'size) 32736)      ; 0x7FE0
(define-values (filled note-fill fill-extra)
  (op-apply 'fill img (hasheq 'start 134217760 'end 134250495 'value 255)))
(check-equal? (image-gaps filled)
              (list (hasheq 'start 134250504 'end 134250511 'size 8)      ; 0x08008008..0x0800800F
                    (hasheq 'start 134250520 'end 134258671 'size 8152))) ; 0x08008018..0x08009FEF
(check-equal? (image-total filled) (+ 64 32736))
(check-equal? note-fill 'note-fill)
(check-equal? (hash-ref fill-extra 'value) 255)

;; Fill bounds: reversed range and oversized range block.
(check-exn exn:fail:bitsmith?
          (lambda () (op-apply 'fill img (hasheq 'start 200 'end 100 'value 255))))
(check-exn exn:fail:bitsmith?
          (lambda () (op-apply 'fill img (hasheq 'start 0 'end 1048576 'value 255))))

;; ---- pad -------------------------------------------------------------------

;; Pad to 0x1000 alignment appends through 0x08000FFF.
;; Already-aligned end: 0x0800A000 is 0x1000-aligned, so nothing is added.
(define-values (padded note-pad pad-extra) (op-apply 'pad img (hasheq 'alignment 4096 'value 255)))
(check-equal? (hash-ref pad-extra 'added) 0)
(check-equal? (image-ranges padded) (image-ranges img))

;; Force a padding case: crop the image to end at 0x08008017, pad to 0x1000.
(define cropped-head (image-crop img 134250496 134250519)) ; 0x08008000..0x08008017
(check-equal? (image-total cropped-head) 16)
(define-values (padded2 note-pad2 pad-extra2)
  (op-apply 'pad cropped-head (hasheq 'alignment 4096 'value 0)))
(check-equal? (hash-ref pad-extra2 'added) 4072) ; through 0x08008FFF
(check-equal? (image-total padded2) 4088)

;; Non-power-of-two alignment blocks.
(check-exn exn:fail:bitsmith?
          (lambda () (op-apply 'pad img (hasheq 'alignment 100 'value 255))))

;; ---- offset ----------------------------------------------------------------

(define-values (offset note-offset offset-extra) (op-apply 'offset img (hasheq 'delta 4096)))
(check-equal? (car (image-ranges offset)) (cons 134221824 134221855)) ; 0x08001000
(check-exn exn:fail:bitsmith? (lambda () (op-apply 'offset img (hasheq 'delta -134217729))))

;; ---- crop ------------------------------------------------------------------

(define-values (crop note-crop crop-extra)
  (op-apply 'crop img (hasheq 'start 134250496 'end 134258671))) ; 0x08008000..0x08009FEF
(check-equal? (image-total crop) 16) ; only the two 8-byte records survive
(check-exn exn:fail:bitsmith?
          (lambda () (op-apply 'crop (mkimg '(0 1)) (hasheq 'start 500 'end 600))))

;; ---- merge -----------------------------------------------------------------

;; Sample merges back onto itself: split at the 0x7FE0 gap, APP re-based at
;; 0x08008000 (its own address) — result identical to the sample image.
(define-values (merged note-merge merge-extra) (op-apply 'merge img (hasheq 'base 134250496)))
(check-equal? (image-ranges merged) (image-ranges img))

;; Re-base APP to 0x08008000 - 0x8000 = 0x08000000 would collide with FBL.
(check-exn exn:fail:bitsmith?
          (lambda () (op-apply 'merge img (hasheq 'base 134217728))))

;; Moving APP far away produces a two-segment image at the new base.
(define-values (merged2 note-merge2 merge-extra2)
  (op-apply 'merge img (hasheq 'base 268435456))) ; 0x10000000
(check-equal? (image-total merged2) 64)
(check-equal? (length (image-ranges merged2)) 4)

;; ---- convert ---------------------------------------------------------------

;; HEX target: no byte change.
(define-values (conv-hex note-conv-hex conv-hex-extra)
  (op-apply 'convert img (hasheq 'target 'HEX)))
(check-equal? (image-ranges conv-hex) (image-ranges img))

;; SREC width loss: S1 cannot encode 0x08009FFF.
(check-exn exn:fail:bitsmith?
          (lambda () (op-apply 'convert img (hasheq 'target 'SREC 'width 'S1))))
(check-exn exn:fail:bitsmith?
          (lambda () (op-apply 'convert img (hasheq 'target 'SREC 'width 'S2))))
(define-values (conv-srec note-conv-srec conv-srec-extra)
  (op-apply 'convert img (hasheq 'target 'SREC 'width 'S3)))
(check-equal? conv-srec-extra (hasheq 'out-format 'SREC 'width 'S3 'line 16))

;; BIN materialises gaps under an explicit base.
(define-values (conv-bin note-conv-bin conv-bin-extra)
  (op-apply 'convert img (hasheq 'target 'BIN 'base 134217728 'value 255)))
(check-equal? (length (image-ranges conv-bin)) 1)
(check-equal? (image-total conv-bin) 40960) ; 0x08000000..0x08009FFF span
(check-equal? (image-ref conv-bin 134217760) 255) ; former gap now 0xFF
(check-exn exn:fail:bitsmith?
          (lambda () (op-apply 'convert img (hasheq 'target 'BIN 'base 134217761 'value 255))))

;; ---- CRC -------------------------------------------------------------------

;; CRC-32/MPEG-2 (project preset) over APP 0x08008000..0x08009FFF: the
;; range includes unmapped bytes; the 0xFF policy substitutes them.
(define crc-result
  (op-crc img (hasheq 'preset 'mpeg2 'start 134250496 'end 134258671 'value 'FF)))
(check-equal? (hash-ref crc-result 'bits) 32)
(check-equal? (hash-ref crc-result 'count) 8176)
(check-equal? (hash-ref crc-result 'gaps) 8160) ; only 16 bytes are populated
;; Deterministic value cross-checked below against a direct computation.
(check-equal?
 (hash-ref crc-result 'value)
 (crc-compute
  (bytes-append (list->bytes '(0 80 0 32 1 89 138 8))
                (make-bytes 8 255)      ; hole at 0x08008008..0x0800800F
                (list->bytes '(45 233 240 71 13 240 128 248))
                (make-bytes 8152 255))  ; hole through 0x08009FEF
  (hash-ref crc-presets 'mpeg2)))

;; Reject-gaps policy blocks on the first unmapped address.
(check-exn exn:fail:bitsmith?
          (lambda ()
            (op-crc img (hasheq 'preset 'mpeg2 'start 134250496 'end 134258671 'value 'reject))))
;; Over a fully populated range it computes directly.
(define crc-ok
  (op-crc img (hasheq 'preset 'sum8 'start 134250496 'end 134250503 'value 'reject)))
(check-equal? (hash-ref crc-ok 'gaps) 0)
(check-equal? (hash-ref crc-ok 'value)
              (remainder (foldl + 0 '(0 80 0 32 1 89 138 8)) 256))

;; ---- serialization: BIN preview ---------------------------------------------

(check-equal? (image->bin-hex-preview (image (list (cons 0 (bytes 1 2 3)))) 0 255)
              "01 02 03")
