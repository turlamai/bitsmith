#lang racket/base

;; Intel HEX parsing and record anatomy.
;;
;; A record is a JSON-ready hasheq (rendered by the record view):
;;   index, raw, malformed, ok, type, type-hex, type-name, count,
;;   address (record-relative), absolute (int or 'null), data (listof byte),
;;   data-hex, stored, expected, sum, address-width.
;;
;; Verdicts are computed from the bytes, never stored. Malformed lines are
;; preserved verbatim with ok #f; failed checksums keep the original bytes
;; (never repaired). Absolute addresses resolve through the active
;; extended-address base (types 02/04).

(require racket/string
         racket/list
         racket/match)

(provide intel-type-name
         parse-intel-hex
         intel-line
         intel-data-line
         intel-eof-line
         intel-base-line
         intel-checksum-byte
         srec-checksum-byte
         hex-pairs
         hex-str)

;; ---- hex helpers ----------------------------------------------------------

(define (hex-pairs str)
  ;; "48B1" -> '(72 177); assumes even-length hex characters (checked by caller).
  (let loop ([i 0])
    (if (>= i (string-length str))
        '()
        (cons (string->number (substring str i (+ i 2)) 16)
              (loop (+ i 2))))))

(define (hex-str n width)
  (let ([s (number->string n 16)])
    (string-upcase
     (if (< (string-length s) width)
         (string-append (make-string (- width (string-length s)) #\0) s)
         s))))

(define intel-type-name
  (let ([names (hasheq 0 "Data" 1 "EOF" 2 "Ext segment" 3 "Start segment"
                       4 "Ext linear" 5 "Start linear")])
    (lambda (t) (hash-ref names t "Unknown"))))

(define (intel-checksum-byte payload)
  ;; Two's complement of the payload sum: (0x100 - (sum & 0xFF)) & 0xFF.
  (define sum (for/fold ([s 0]) ([b (in-list payload)]) (+ s b)))
  (bitwise-and (- 256 sum) 255))

(define (srec-checksum-byte payload)
  ;; One's complement of the payload sum: 0xFF - (sum & 0xFF).
  (define sum (for/fold ([s 0]) ([b (in-list payload)]) (+ s b)))
  (bitwise-and (- 255 sum) 255))

(define (malformed-record raw index)
  (hasheq 'index index 'raw raw 'malformed #t 'ok #f
          'type 'null 'type-hex "??" 'type-name "Malformed"
          'count 'null 'address 'null 'absolute 'null
          'data '() 'data-hex "" 'data-bytes 0
          'stored 'null 'expected 'null 'sum 'null
          'address-width 4))

;; ---- parsing --------------------------------------------------------------

;; parse-intel-hex : string -> (listof record-hasheq)
(define (split-lines text)
  ;; Accept CRLF, LF and CR; drop blank lines.
  (filter (lambda (l) (not (string=? l "")))
          (map string-trim
               (string-split
                (string-replace (string-replace text "\r\n" "\n") "\r" "\n")
                "\n"))))

(define (parse-intel-hex text)
  (define lines (split-lines text))
  (let loop ([lines lines] [index 0] [base 0] [out '()])
    (match lines
      ['() (reverse out)]
      [(cons raw rest)
       (define record
         (cond
           [(or (< (string-length raw) 1)
                (not (char=? (string-ref raw 0) #\:)))
            (malformed-record raw index)]
           [(let ([body (substring raw 1)])
              (or (< (string-length body) 10) ; count+address+type+checksum at minimum
                  (odd? (string-length body))
                  (not (regexp-match? #rx"^[0-9A-Fa-f]*$" body))))
            (malformed-record raw index)]
           [(let* ([bytes (hex-pairs (substring raw 1))]
                   [count (list-ref bytes 0)])
              (< (length bytes) (+ 5 count)))
            (malformed-record raw index)]
           [else
            (define bytes (hex-pairs (substring raw 1)))
            (define count (list-ref bytes 0))
            (define address (+ (* (list-ref bytes 1) 256) (list-ref bytes 2)))
            (define type (list-ref bytes 3))
            (define data (drop (take bytes (+ 4 count)) 4))
            (define stored (list-ref bytes (+ 4 count)))
            (define sum (for/fold ([s 0]) ([b (in-list (take bytes (+ 4 count)))]) (+ s b)))
            (define expected (bitwise-and (- 256 sum) 255))
            (define ok (and (= (length data) count) (= stored expected)))
            ;; Base update happens for the record being parsed (types 02/04
            ;; set the base for FOLLOWING records; their own absolute is the
            ;; new base itself).
            (define base2
              (cond
                [(and (= type 2) (>= (length data) 2))
                 (arithmetic-shift (+ (* (list-ref data 0) 256) (list-ref data 1)) 4)]
                [(and (= type 4) (>= (length data) 2))
                 (arithmetic-shift (+ (* (list-ref data 0) 256) (list-ref data 1)) 16)]
                [else base]))
            (define absolute
              (cond
                [(= type 0) (+ base address)]
                [(= type 2) base2]
                [(= type 4) base2]
                [(= type 3) (if (>= (length data) 4)
                                (+ (arithmetic-shift (+ (* (list-ref data 0) 256)
                                                       (list-ref data 1)) 4)
                                   (+ (* (list-ref data 2) 256) (list-ref data 3)))
                                'null)]
                [(= type 5) (if (>= (length data) 4)
                                (bitwise-and
                                 (+ (* (list-ref data 0) 16777216)
                                    (* (list-ref data 1) 65536)
                                    (* (list-ref data 2) 256)
                                    (list-ref data 3))
                                 4294967295)
                                'null)]
                [else 'null]))
            (hasheq 'index index 'raw raw 'malformed #f 'ok ok
                    'type type 'type-hex (hex-str type 2)
                    'type-name (intel-type-name type)
                    'count count 'address address 'absolute absolute
                    'data data
                    'data-hex (string-join (map (lambda (b) (hex-str b 2)) data) " ")
                    'data-bytes (length data)
                    'stored stored 'expected expected 'sum sum
                    'address-width 4)]))
       (loop rest
             (add1 index)
             ;; The base carries forward only through 02/04 records.
             (let ([t (hash-ref record 'type)])
               (cond [(not (number? t)) base]
                     [(= t 2) (hash-ref record 'absolute base)]
                     [(= t 4) (hash-ref record 'absolute base)]
                     [else base]))
             (cons record out))])))

;; ---- serialization --------------------------------------------------------

(define (intel-data-line address data)
  ;; data: bytes or a list of bytes 0..255; the line is assembled as bytes.
  (define data-bytes (if (bytes? data) data (list->bytes data)))
  (define payload
    (bytes-append
     (bytes (bytes-length data-bytes)
            (bitwise-and (arithmetic-shift address -8) 255)
            (bitwise-and address 255)
            0)
     data-bytes))
  (define sum
    (for/fold ([s 0]) ([b (in-bytes payload)]) (+ s b)))
  (string-append ":"
                 (string-join (for/list ([b (in-bytes payload)]) (hex-str b 2)) "")
                 (hex-str (bitwise-and (- 256 sum) 255) 2)))

(define (intel-line payload)
  (string-append ":"
                 (string-join (map (lambda (b) (hex-str b 2)) payload) "")
                 (hex-str (intel-checksum-byte payload) 2)))

(define (intel-base-line upper)
  ;; Type 04 extended linear address record for the upper 16 bits.
  (intel-line (list 2 0 0 4
                    (bitwise-and (arithmetic-shift upper -8) 255)
                    (bitwise-and upper 255))))

(define (intel-eof-line)
  ":00000001FF")
