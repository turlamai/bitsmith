#lang racket/base

;; The seven operations behind the Operations screen. Each takes the
;; working image plus validated integer parameters and returns
;; (values image note-key extra) — or raises exn:fail:bitsmith with a
;; stable key the API layer localizes.
;;
;; Bounds pinned by the design contract: preview and CRC range processing
;; is bounded to 1 MiB; address arithmetic is unsigned 32-bit.

(require racket/list
         racket/match
         racket/string
         "crc.rkt"
         "image.rkt"
         "serialize.rkt")

(provide preview-bound
         op-apply
         op-crc
         parse-address-text
         parse-signed-text)

(define preview-bound 1048576) ; 1 MiB

;; ---- parameter text parsing (addresses arrive as "0x..." or decimal) -------

(define (parse-address-text text)
  (unless (regexp-match? #rx"^(?:0[xX][0-9a-fA-F]+|[0-9]+)$" (string-trim text))
    (raise-bitsmith-error 'err-address-format))
  (define n (string->number (string-trim text) 10)) ; decimal first
  (define value
    (if (regexp-match? #rx"^0[xX]" (string-trim text))
        (string->number (substring (string-trim text) 2) 16)
        n))
  (unless (and value (exact-positive-integer? value) (<= value 4294967295))
    (raise-bitsmith-error 'err-address-out-of-range))
  value)

(define (parse-signed-text text)
  (define t (string-trim text))
  (define negative (string-prefix? t "-"))
  (define magnitude (if negative (substring t 1) t))
  (unless (regexp-match? #rx"^(?:0[xX][0-9a-fA-F]+|[0-9]+)$" magnitude)
    (raise-bitsmith-error 'err-address-format))
  (define n
    (if (regexp-match? #rx"^0[xX]" magnitude)
        (string->number (substring magnitude 2) 16)
        (string->number magnitude 10)))
  (unless (and n (exact-positive-integer? n) (<= n 4294967295))
    (raise-bitsmith-error 'err-address-out-of-range))
  (if negative (- n) n))

;; ---- range validation ------------------------------------------------------

(define (checked-range start end)
  (when (> start end) (raise-bitsmith-error 'err-start-above-end))
  (when (> end 4294967295) (raise-bitsmith-error 'err-address-out-of-range))
  (when (> (+ (- end start) 1) preview-bound)
    (raise-bitsmith-error 'err-range-too-large))
  (values start end))

;; ---- operations ------------------------------------------------------------

;; op-apply : symbol image hash -> (values image note-key extra-hash)
(define (op-apply op img params)
  (case op
    [(fill) (op-fill img params)]
    [(pad) (op-pad img params)]
    [(offset) (op-offset img params)]
    [(crop) (op-crop img params)]
    [(merge) (op-merge img params)]
    [(convert) (op-convert img params)]
    [else (raise-bitsmith-error 'err-unknown-op)]))

(define (op-fill img params)
  (define start (hash-ref params 'start))
  (define end (hash-ref params 'end))
  (define value (hash-ref params 'value))
  (unless (and (<= 0 value 255)) (raise-bitsmith-error 'err-value-out-of-range))
  (define-values (s e) (checked-range start end))
  (values (image-fill-range img s e value)
          'note-fill
          (hasheq 'start s 'end e 'value value)))

(define (op-pad img params)
  (define alignment (hash-ref params 'alignment))
  (define value (hash-ref params 'value))
  (unless (and (<= 0 value 255)) (raise-bitsmith-error 'err-value-out-of-range))
  (unless (and (<= 1 alignment preview-bound)
               (= (bitwise-and alignment (sub1 alignment)) 0))
    (raise-bitsmith-error 'err-alignment-invalid))
  (define-values (lo hi) (image-bounds img))
  (when (not hi) (raise-bitsmith-error 'err-empty-image))
  (define stop (* (ceiling (/ (+ hi 1) alignment)) alignment))
  (when (> stop 4294967296) (raise-bitsmith-error 'err-relocation-out-of-range))
  (if (= stop (+ hi 1))
      (values img 'note-pad-aligned (hasheq 'added 0))
      (values (image-fill-range img (+ hi 1) (sub1 stop) value)
              'note-pad
              (hasheq 'added (- stop hi 1) 'end (sub1 stop)))))

(define (op-offset img params)
  (define delta (hash-ref params 'delta))
  (values (image-offset img delta)
          'note-offset
          (hasheq 'delta delta)))

(define (op-crop img params)
  (define start (hash-ref params 'start))
  (define end (hash-ref params 'end))
  (define-values (s e) (checked-range start end))
  (define cropped (image-crop img s e))
  (when (= (image-total cropped) 0)
    (raise-bitsmith-error 'err-crop-empty))
  (values cropped 'note-crop (hasheq 'start s 'end e)))

;; Merge: the image splits at its largest gap — everything below stays put,
;; everything above relocates to the explicit destination base preserving
;; its internal layout. This generalizes the supplied sample's FBL/APP
;; behavior (FBL in place, APP re-based) to any two-part image. An image
;; without a gap has nothing to merge; overlap blocks the apply.
(define (op-merge img params)
  (define base (hash-ref params 'base))
  (define gaps (image-gaps img))
  (unless (pair? gaps)
    (raise-bitsmith-error 'err-merge-two-segments))
  (define split-gap
    (foldl (lambda (g best)
             (if (> (hash-ref g 'size) (hash-ref best 'size)) g best))
           (car gaps) gaps))
  (define part1 (image-crop img 0 (sub1 (hash-ref split-gap 'start))))
  (define part2 (image-crop img (hash-ref split-gap 'end) 4294967295))
  (when (= (image-total part1) 0) (raise-bitsmith-error 'err-merge-two-segments))
  (when (= (image-total part2) 0) (raise-bitsmith-error 'err-merge-two-segments))
  (define part2-lo
    (car (car (image-ranges part2))))
  (define delta (- base part2-lo))
  (define relocated (image-offset part2 delta))
  (define overlap (image-overlap-at part1 relocated))
  (when overlap
    (raise-bitsmith-error 'err-merge-overlap (hasheq 'address overlap)))
  (values (image-union part1 relocated)
          'note-merge
          (hasheq 'base base)))

;; Convert: HEX/SREC targets change the working format without touching
;; bytes; BIN materialises gaps with the explicit fill value under an
;; explicit base assumption.
(define (op-convert img params)
  (define target (hash-ref params 'target)) ; 'HEX | 'SREC | 'BIN
  (define width (hash-ref params 'width 'S3))
  (define line-size (hash-ref params 'line 16))
  (define fill (hash-ref params 'value 255))
  (define base (hash-ref params 'base 134217728)) ; 0x08000000
  (define-values (lo hi) (image-bounds img))
  (when (not hi) (raise-bitsmith-error 'err-empty-image))
  (case target
    [(HEX)
     (values img 'note-convert-hex (hasheq 'out-format 'HEX))]
    [(SREC)
     (when (> hi (srec-width-limit width))
       (raise-bitsmith-error 'err-width-loss))
     (values img 'note-convert-srec
             (hasheq 'out-format 'SREC 'width width 'line line-size))]
    [(BIN)
     (when (> base lo) (raise-bitsmith-error 'err-bin-base-above-start))
     (when (> (+ (- hi base) 1) preview-bound)
       (raise-bitsmith-error 'err-bin-too-large))
     (values (image (list (cons base (image->bin-bytes img base fill))))
             'note-convert-bin
             (hasheq 'out-format 'BIN 'base base))]
    [else (raise-bitsmith-error 'err-unknown-op)]))

;; CRC is read-only: the working image never changes, no stored CRC is
;; assumed and there is no match verdict.
;; op-crc : image hash -> hash
(define (op-crc img params)
  (define preset-id (hash-ref params 'preset))
  (define preset (hash-ref crc-presets preset-id #f))
  (unless preset (raise-bitsmith-error 'err-unknown-preset))
  (define policy (hash-ref params 'value)) ; 'FF | '00 | 'reject
  (define-values (s e) (checked-range (hash-ref params 'start) (hash-ref params 'end)))
  (define bytes-out '())
  (define gaps 0)
  (let loop ([a s])
    (when (<= a e)
      (define b (image-ref img a))
      (cond
        [b (set! bytes-out (cons b bytes-out))]
        [(eq? policy 'reject)
         (raise-bitsmith-error 'crc-unmapped-at (hasheq 'address a))]
        [else
         (set! gaps (add1 gaps))
         (set! bytes-out (cons (if (eq? policy 'FF) 255 0) bytes-out))])
      (loop (add1 a))))
  (define value (crc-compute (reverse bytes-out) preset))
  (hasheq 'value value
          'bits (hash-ref preset 'bits)
          'count (- e s -1)
          'gaps gaps
          'poly (hash-ref preset 'poly)
          'init (hash-ref preset 'init)
          'xor (hash-ref preset 'xor)
          'reflect (hash-ref preset 'reflect)
          'note-key (hash-ref preset 'note-key)
          'label (hash-ref preset 'label)))
