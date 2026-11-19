#lang racket/base

;; Canonical record generation from an image, used by operation previews,
;; record-count comparisons and file save.
;;
;; Canonical output is newly generated: line grouping may differ from the
;; supplied source. Intel HEX chunks never cross a 64 KiB boundary and a
;; type-04 extended-linear record is emitted whenever the upper 16 bits
;; change. S-record width selects the address field; width loss must be
;; blocked by the caller before serialization.

(require racket/list
         racket/string
         "hex.rkt"
         "srec.rkt"
         "image.rkt")

(provide image->intel-lines
         image->srec-lines
         image->bin-bytes
         image->bin-hex-preview
         image->record-count
         srec-width-limit
         srec-terminator-line
         intel-eof-line)

(define line-cap 65536)

;; Intel HEX canonical lines (16 data bytes per line by default).
(define (image->intel-lines img [line-size 16])
  (define out '())
  (define upper-set #f)
  (define upper 0)
  (for ([range (in-list (image-ranges img))])
    (define start (car range))
    (define end (cdr range))
    (define run (for/first ([r (in-list (image-runs img))] #:when (= (car r) start)) (cdr r)))
    (let loop ([at start] [offset 0])
      (when (<= at end)
        (define room (- end at -1))
        (define boundary-room (- line-cap (remainder at line-cap)))
        (define size (min line-size room boundary-room))
        (define new-upper (quotient at line-cap))
        (when (or (not upper-set) (not (= new-upper upper)))
          (set! upper new-upper)
          (set! upper-set #t)
          (set! out (cons (intel-base-line upper) out)))
        (set! out (cons (intel-data-line at (subbytes run offset (+ offset size))) out))
        (loop (+ at size) (+ offset size)))))
  (reverse (cons (intel-eof-line) out)))

(define (srec-width-limit width)
  (case width
    [(S1) 65535]
    [(S2) 16777215]
    [else 4294967295]))

;; S-record canonical lines.
(define (image->srec-lines img [width 'S3] [line-size 16])
  (define addr-len (case width [(S1) 2] [(S2) 3] [else 4]))
  (define out '())
  (for ([range (in-list (image-ranges img))])
    (define start (car range))
    (define end (cdr range))
    (define run (for/first ([r (in-list (image-runs img))] #:when (= (car r) start)) (cdr r)))
    (let loop ([at start] [offset 0])
      (when (<= at end)
        (define size (min line-size (- end at -1)))
        (set! out (cons (srec-data-line at (subbytes run offset (+ offset size)) width) out))
        (loop (+ at size) (+ offset size)))))
  (reverse (cons (srec-terminator-line width) out)))

;; Canonical record count without materialising the whole text: data
;; records plus base records plus the terminator/EOF line.
(define (image->record-count img [width 'S3] [line-size 16])
  (define bases
    (length
     (remove-duplicates
      (for/list ([range (in-list (image-ranges img))])
        (quotient (car range) line-cap)))))
  (+ (length (image-ranges img)) bases 1))

;; Raw BIN: materialise every hole from base through the last populated
;; byte. Caller enforces the size bound.
(define (image->bin-bytes img base fill)
  (define-values (lo hi) (image-bounds img))
  (cond
    [(not lo) (bytes)]
    [(> base lo)
     (raise-bitsmith-error 'bin-base-above-start)]
    [else
     (define total (+ (- hi base) 1))
     (define buf (make-bytes total fill))
     (for ([run (in-list (image-runs img))])
       (for ([i (in-naturals (car run))] [b (in-bytes (cdr run))])
         (bytes-set! buf (- i base) b)))
     buf]))

;; Short hex preview of the materialised BIN (first 64 bytes), matching
;; the prototype's conversion output preview.
(define (image->bin-hex-preview img base fill [preview-bytes 64])
  (define buf (image->bin-bytes img base fill))
  (define n (min preview-bytes (bytes-length buf)))
  (string-join
   (for/list ([i (in-range n)])
     (byte-hex (bytes-ref buf i)))
   " "))

(define (byte-hex b)
  (define s (number->string b 16))
  (string-upcase (if (< (string-length s) 2) (string-append "0" s) s)))
