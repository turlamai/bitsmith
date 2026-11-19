#lang racket/base

;; Intel HEX parser tests against the verified synthetic sample set
;; (shared/spec.md — every checksum round-trip checks).

(require rackunit
         racket/list
         racket/string
         "hex.rkt")

;; 7 of 8 verify (live arithmetic, not stored verdicts).
(define (hash-ref-ok record) (hash-ref record 'ok))

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

(define records (parse-intel-hex sample-text))

;; 8 lines -> 8 records, in order, raw preserved verbatim.
(check-equal? (length records) 8)
(check-equal? (hash-ref (list-ref records 0) 'raw) ":020000040800F2")

;; Record 1: type 04 sets base 0x08000000, checksum verifies.
(define r0 (list-ref records 0))
(check-equal? (hash-ref r0 'type) 4)
(check-equal? (hash-ref r0 'absolute) 134217728) ; 0x08000000
(check-equal? (hash-ref r0 'ok) #t)

;; Data record 2: 32 bytes at 0x08000000, payload starts 00 10 02 00 09 59 01 08.
(define r1 (list-ref records 1))
(check-equal? (hash-ref r1 'type) 0)
(check-equal? (hash-ref r1 'absolute) 134217728)
(check-equal? (hash-ref r1 'count) 32)
(check-equal? (hash-ref r1 'stored) 123) ; 0x7B
(check-equal? (hash-ref r1 'expected) 123)
(check-equal? (hash-ref r1 'ok) #t)
(check-equal? (take (hash-ref r1 'data) 8) '(0 16 2 0 9 89 1 8))

;; Data record 3: 16 bytes of 0xFF at 0x08000010 (overlaps record 2's tail).
(define r2 (list-ref records 2))
(check-equal? (hash-ref r2 'absolute) 134217744) ; 0x08000010
(check-equal? (hash-ref r2 'stored) 240) ; 0xF0
(check-equal? (hash-ref r2 'ok) #t)

;; APP records at 0x08008000 / 0x08008010.
(check-equal? (hash-ref (list-ref records 3) 'absolute) 134250496) ; 0x08008000
(check-equal? (hash-ref (list-ref records 3) 'data) '(0 80 0 32 1 89 138 8))
(check-equal? (hash-ref (list-ref records 4) 'absolute) 134250512) ; 0x08008010

;; Explicit 0xFF tail at 0x08009FF0.
(check-equal? (hash-ref (list-ref records 5) 'absolute) 134258672) ; 0x08009FF0
(check-equal? (hash-ref (list-ref records 5) 'count) 16)

;; The deliberately corrupted record keeps its bytes, verdict computed live.
;; Expected checksum is 0x14 (14); the line stores 0x00.
(define bad (list-ref records 6))
(check-equal? (hash-ref bad 'ok) #f)
(check-equal? (hash-ref bad 'stored) 0)
(check-equal? (hash-ref bad 'expected) 20)
(check-equal? (hash-ref bad 'sum) 492) ; 0x1EC
(check-equal? (hash-ref bad 'absolute) 134250528) ; 0x08008020
(check-equal? (hash-ref bad 'data) '(72 177 8 71))
(check-equal? (hash-ref bad 'raw) ":0480200048B1084700")

;; EOF record.
(check-equal? (hash-ref (list-ref records 7) 'type) 1)
(check-equal? (hash-ref (list-ref records 7) 'ok) #t)

;; 7 of 8 verify (live arithmetic, not stored verdicts).
(check-equal? (length (filter hash-ref-ok records)) 7)

;; ---- malformed handling ---------------------------------------------------

;; Not starting with ':', odd nibble count, non-hex, truncated payload.
(check-equal? (hash-ref (car (parse-intel-hex "XX020000040800F2")) 'malformed) #t)
(check-equal? (hash-ref (car (parse-intel-hex ":02000004080")) 'malformed) #t)
(check-equal? (hash-ref (car (parse-intel-hex ":020000040800ZZ")) 'malformed) #t)
;; Count declares 4 data bytes; line stops after the address bytes.
(check-equal? (hash-ref (car (parse-intel-hex ":04000004080")) 'malformed) #t)
;; Short but consistent line still parses (count 0 + checksum).
(check-equal? (hash-ref (car (parse-intel-hex ":00000001FF")) 'malformed) #f)

;; CRLF and blank lines are tolerated; extensionless content is not a parser concern.
(define crlf (string-append ":00000001FF\r\n\r\n"))
(check-equal? (length (parse-intel-hex crlf)) 1)
(check-equal? (length (parse-intel-hex ":00000001FF\r:00000001FF")) 2)

;; ---- serialization --------------------------------------------------------

;; Canonical helper lines carry valid checksums by construction.
(check-equal? (intel-eof-line) ":00000001FF")
(check-equal? (intel-base-line 2048) ":020000040800F2")
(define base-line (intel-base-line 2048))
(check-equal?
 (hash-ref (car (parse-intel-hex base-line)) 'ok) #t)
(check-equal?
 (hash-ref (car (parse-intel-hex base-line)) 'absolute) 134217728)

;; Checksum helpers agree with the recorded expected values.
(check-equal? (intel-checksum-byte '(2 0 0 4 8 0)) 242) ; 0xF2
(check-equal? (srec-checksum-byte '(5 0 0 0 0)) 250) ; 0xFA

;; A data line built by intel-data-line parses back to the same bytes.
(define built (intel-data-line 2048 (list 1 2 3 4))) ;; 16-bit record address
(define parsed-back (car (parse-intel-hex built)))
(check-equal? (hash-ref parsed-back 'ok) #t)
(check-equal? (hash-ref parsed-back 'data) '(1 2 3 4))
(check-equal? (hash-ref parsed-back 'absolute) 2048)

;; Sample source preserved verbatim through the parser.
(check-equal? (map (lambda (r) (hash-ref r 'raw)) records)
              (map string-trim (string-split (string-replace (string-replace sample-text "\r\n" "\n") "\r" "\n") "\n")))

;; ---- S-record basics (checksum helper + parse shape live in srec.rkt) ------

(check-equal? (hex-pairs "48B10847") '(72 177 8 71))
