#lang racket/base

;; Motorola S-record parser tests against the verified synthetic sample
;; (shared/spec.md) plus malformed/round-trip coverage.

(require rackunit
         racket/list
         racket/string
         "srec.rkt")

(define sample-text
  (string-append
   "S0120000496D61676542656E63682D44454D4FD8\r\n"
   "S31D004000000050002001598A08FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF56\n"
   "S31D004000182DE9F0470DF080F800000000000000000000000000000000C8\n"
   "S3150054FFF0FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFB7\n"
   "S70500000000FA"))

(define records (parse-srec sample-text))

(check-equal? (length records) 5)

;; S0 header: no absolute address, checksum verifies, name decoded in data.
(define s0 (list-ref records 0))
(check-equal? (hash-ref s0 'ok) #t)
(check-equal? (hash-ref s0 'type-hex) "S0")
(check-equal? (hash-ref s0 'absolute) 'null)
(check-equal? (hash-ref s0 'count) 18)

;; Data records carry absolute addresses (0x00400000, 0x00400018, 0x0054FFF0).
(check-equal? (hash-ref (list-ref records 1) 'absolute) 4194304)
(check-equal? (hash-ref (list-ref records 1) 'data-bytes) 24)
(check-equal? (take (hash-ref (list-ref records 1) 'data) 8)
              '(0 80 0 32 1 89 138 8))
(check-equal? (hash-ref (list-ref records 2) 'absolute) 4194328)
(check-equal? (hash-ref (list-ref records 3) 'absolute) 5570544)

;; Every sample record verifies (live arithmetic).
(check-equal? (length (filter (lambda (r) (hash-ref r 'ok)) records)) 5)

;; Termination record: start address 0, checksum FA.
(define s7 (list-ref records 4))
(check-equal? (hash-ref s7 'type-hex) "S7")
(check-equal? (hash-ref s7 'absolute) 0)
(check-equal? (hash-ref s7 'ok) #t)

;; ---- serialization round-trip ---------------------------------------------

;; A generated S3 data line parses back to the same address and bytes.
(define rebuilt (srec-data-line 4194304 '(1 2 3 4) 'S3))
(define round-trip (car (parse-srec rebuilt)))
(check-equal? (hash-ref round-trip 'ok) #t)
(check-equal? (hash-ref round-trip 'absolute) 4194304)
(check-equal? (hash-ref round-trip 'data) '(1 2 3 4))
(check-equal? (hash-ref round-trip 'count) 9) ; 4 address + 4 data + 1 checksum

;; Terminators carry valid checksums (zero start address).
(for ([width '(S1 S2 S3)])
  (check-equal? (hash-ref (car (parse-srec (srec-terminator-line width))) 'ok) #t))

;; ---- address widths --------------------------------------------------------

;; S1 tops out at 0xFFFF; S2 at 0xFFFFFF (the UI blocks width loss before us).
(check-equal? (hash-ref (car (parse-srec (srec-data-line 65535 '(9) 'S1))) 'ok) #t)
(check-equal? (hash-ref (car (parse-srec (srec-data-line 16777215 '(9) 'S2))) 'ok) #t)
(check-equal? (hash-ref (car (parse-srec (srec-data-line 4294967295 '(9) 'S3))) 'ok) #t)

;; ---- malformed handling ----------------------------------------------------

(check-equal? (hash-ref (car (parse-srec "X31000000FA")) 'malformed) #t)
(check-equal? (hash-ref (car (parse-srec "S31000000F")) 'malformed) #t) ; odd nibbles
(check-equal? (hash-ref (car (parse-srec "SZ10000000F0")) 'malformed) #t)
(check-equal? (hash-ref (car (parse-srec "S31D0040")) 'malformed) #t) ; truncated

;; A checksum failure is not malformed: bytes preserved, verdict computed.
(define failed (parse-srec "S31D004000000050002001598A08FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF57"))
(check-equal? (hash-ref (car failed) 'malformed) #f)
(check-equal? (hash-ref (car failed) 'ok) #f)
(check-equal? (hash-ref (car failed) 'stored) 87)
(check-equal? (hash-ref (car failed) 'expected) 86)
