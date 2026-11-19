#lang racket/base

;; Motorola S-record parsing and record anatomy.
;;
;; Record shape matches hex.rkt (one hasheq per line, JSON-ready):
;; type is the S-number as a string ("0".."9"), type-hex "S<n>".
;; Absolute addresses exist only for data records (S1/S2/S3) and start
;; records (S7/S8/S9); S5/S6 count records report their count value without
;; an absolute address. S6 (24-bit count) is parsed even though the
;; prototype skipped it — the format matrix lists the full S0–S9 family.
;;
;; CRLF and LF both accepted; checksums are computed live (one's complement
;; of count+address+data).

(require racket/string
         racket/list
         racket/match
         "hex.rkt") ; hex-pairs, srec-checksum-byte

(provide parse-srec
         srec-type-name
         srec-address-length
         srec-terminator-line
         srec-data-line)

(define srec-type-name
  (let ([names (hasheq "0" "Header" "1" "Data 16" "2" "Data 24" "3" "Data 32"
                       "5" "Count" "6" "Count 24" "7" "Start 32"
                       "8" "Start 24" "9" "Start 16")])
    (lambda (t) (hash-ref names t "Unknown"))))

;; Address field length in bytes per record type.
(define (srec-address-length type-char)
  (case type-char
    [("1" "5" "9") 2]
    [("2" "6" "8") 3]
    [("3" "7") 4]
    [("0") 2]
    [else #f]))

(define (malformed-record raw index)
  (hasheq 'index index 'raw raw 'malformed #t 'ok #f
          'type 'null 'type-hex "??" 'type-name "Malformed"
          'count 'null 'address 'null 'absolute 'null
          'data '() 'data-hex "" 'data-bytes 0
          'stored 'null 'expected 'null 'sum 'null
          'address-width 8))

(define (parse-srec text)
  (define lines
    (filter (lambda (l) (not (string=? l "")))
            (map string-trim (string-split text "\n"))))
  (let loop ([lines lines] [index 0] [out '()])
    (match lines
      ['() (reverse out)]
      [(cons raw rest)
       (define record
         (cond
           [(< (string-length raw) 2)
            (malformed-record raw index)]
           [(not (regexp-match? #rx"^[sS][0-9A-Fa-f]+$" raw))
            (malformed-record raw index)]
           [else
            (define type-char (string-upcase (substring raw 1 2)))
            (define addr-len (srec-address-length type-char))
            (cond
              [(not addr-len)
               (malformed-record raw index)]
              [(let ([payload (substring raw 2)])
                 (or (< (string-length payload) (+ (* (+ addr-len 1) 2) 2)) ; addr + count + checksum minimum
                     (odd? (string-length payload))
                     (not (regexp-match? #rx"^[0-9A-Fa-f]+$" payload))))
               (malformed-record raw index)]
              [else
               (define bytes (hex-pairs (substring raw 2)))
               (define declared-count (car bytes))
               (define address-bytes (take (drop bytes 1) addr-len))
               (define data (drop (take bytes (- (length bytes) 1)) (add1 addr-len)))
               (define stored (list-ref bytes (- (length bytes) 1)))
               ;; Sum covers count + address + data.
               (define sum
                 (+ declared-count
                    (foldl + 0 address-bytes)
                    (foldl + 0 data)))
               (define expected (bitwise-and (- 255 sum) 255))
               (define ok (and (= (length bytes) (add1 declared-count))
                               (= stored expected)))
               (define address
                 (for/fold ([acc 0]) ([b (in-list address-bytes)])
                   (+ (* acc 256) b)))
               (define is-data (match type-char ["1" #t] ["2" #t] ["3" #t] [_ #f]))
               (define is-start (match type-char ["7" #t] ["8" #t] ["9" #t] [_ #f]))
               (hasheq 'index index 'raw raw 'malformed #f 'ok ok
                       'type type-char 'type-hex (string-append "S" type-char)
                       'type-name (srec-type-name type-char)
                       'count declared-count 'address address
                       'absolute (if (or is-data is-start) address 'null)
                       'data data
                       'data-hex (string-join (map (lambda (b) (byte-str b)) data) " ")
                       'data-bytes (length data)
                       'stored stored 'expected expected 'sum sum
                       'address-width 8)])]))
       (loop rest (add1 index) (cons record out))])))

;; ---- serialization --------------------------------------------------------

(define (byte-str b)
  (let ([s (number->string b 16)])
    (string-upcase
     (if (< (string-length s) 2)
         (string-append "0" s)
         s))))

(define (address-str address addr-len)
  (let ([s (number->string address 16)])
    (string-upcase
     (if (< (string-length s) (* addr-len 2))
         (string-append (make-string (- (* addr-len 2) (string-length s)) #\0) s)
         s))))

(define (srec-data-line address data width)
  ;; data: bytes or a list of bytes 0..255.
  (define data-bytes (if (bytes? data) data (list->bytes data)))
  (define addr-len (case width [(S1) 2] [(S2) 3] [else 4]))
  (define type-char (case width [(S1) "1"] [(S2) "2"] [else "3"]))
  (define count (+ addr-len (bytes-length data-bytes) 1))
  (define address-bytes
    (for/list ([i (in-range (- addr-len 1) -1 -1)])
      (bitwise-and (arithmetic-shift address (* -8 i)) 255)))
  (define payload (bytes-append (bytes count) (list->bytes address-bytes) data-bytes))
  (define sum
    (+ count (foldl + 0 address-bytes)
       (for/fold ([s 0]) ([b (in-bytes data-bytes)]) (+ s b))))
  (string-append "S" type-char
                 (string-join (map byte-str (bytes->list payload)) "")
                 (byte-str (bitwise-and (- 255 sum) 255))))

(define (srec-terminator-line width)
  ;; Start records with a zero execution address, matching the canonical
  ;; output contract (no invented entry point).
  (case width
    [(S1) "S9030000FC"]
    [(S2) "S804000000FB"]
    [else "S70500000000FA"]))
