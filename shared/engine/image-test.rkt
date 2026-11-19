#lang racket/base

;; Image model tests: last-wins overlap, trim/insert edges, gaps, segments,
;; rows, diff counts and merge-overlap detection.
;;
;; Run literals are (start byte ...) — a run covers start..start+len-1.

(require rackunit
         racket/list
         "image.rkt")

(define (img . runs)
  (foldl (lambda (run acc)
           (image-set-run acc (car run) (apply bytes (cdr run))))
         empty-image runs))

;; ---- construction ----------------------------------------------------------

(define i0 (img '(100 1 2 3 4))) ; 100..103
(check-equal? (image-total i0) 4)
(check-equal? (image-ranges i0) '((100 . 103)))
(check-equal? (image-ref i0 100) 1)
(check-equal? (image-ref i0 103) 4)
(check-equal? (image-ref i0 99) #f)
(check-equal? (image-ref i0 104) #f)

;; Adjacent runs coalesce.
(define i1 (img '(100 1 2) '(102 3 4))) ; 100..101 + 102..103
(check-equal? (image-ranges i1) '((100 . 103)))
(check-equal? (image-total i1) 4)

;; Disjoint runs stay separate.
(define i2 (img '(100 1) '(200 2)))
(check-equal? (image-ranges i2) '((100 . 100) (200 . 200)))

;; Last-wins: full overwrite of the only run.
(define i3 (img '(100 1 2 3) '(100 9))) ; second run covers 100 only
(check-equal? (image-total i3) 3)
(check-equal? (image-ref i3 100) 9)
(check-equal? (image-ref i3 101) 2)
(check-equal? (image-ref i3 102) 3)

;; Full overwrite including the whole first run.
(define i3b (img '(100 1 2) '(100 9 9 9))) ; 100..102 replaces 100..101
(check-equal? (image-total i3b) 3)
(check-equal? (image-ranges i3b) '((100 . 102)))
(check-equal? (image-ref i3b 100) 9)
(check-equal? (image-ref i3b 102) 9)

;; Last-wins: head overwrite (bytes 100..101 stay, 102 becomes 9).
(define i4 (img '(100 1 2 3 4 5) '(102 9))) ; first 100..104, second 102
(check-equal? (image-ranges i4) '((100 . 104)))
(check-equal? (image-ref i4 100) 1)
(check-equal? (image-ref i4 101) 2)
(check-equal? (image-ref i4 102) 9)
(check-equal? (image-ref i4 103) 4)

;; Last-wins: mid overwrite with tail surviving.
(define i5 (img '(100 1 2 3 4 5) '(103 9)))
(check-equal? (image-ranges i5) '((100 . 104)))
(check-equal? (image-ref i5 102) 3)
(check-equal? (image-ref i5 103) 9)
(check-equal? (image-ref i5 104) 5)

;; Multi-run overlap: one wide write over two existing runs keeps the tail.
(define i6 (img '(100 1 1 1) '(104 2 2 2) '(100 7 7 7 7 7)))
(check-equal? (image-ranges i6) '((100 . 106)))
(check-equal? (image-ref i6 100) 7)
(check-equal? (image-ref i6 104) 7)
(check-equal? (image-ref i6 105) 2) ; second run's tail survives
(check-equal? (image-ref i6 106) 2)

;; Insertion below the lowest run keeps ascending order.
(define i7 (img '(200 2) '(100 1)))
(check-equal? (image-ranges i7) '((100 . 100) (200 . 200)))

;; ---- removal ---------------------------------------------------------------

;; Middle removal splits a run.
(define r1 (image-remove-range i0 101 102))
(check-equal? (image-ranges r1) '((100 . 100) (103 . 103)))
(check-equal? (image-ref r1 100) 1)
(check-equal? (image-ref r1 103) 4)

;; Removal spanning nothing changes nothing.
(check-equal? (image-ranges (image-remove-range i0 500 600)) '((100 . 103)))

;; Removal of the whole image.
(check-equal? (image-ranges (image-remove-range i0 0 4294967295)) '())

;; Removal across multiple runs.
(define r2 (image-remove-range i2 50 250))
(check-equal? (image-ranges r2) '())

;; Crop keeps the inclusive range.
(define c1 (image-crop i1 101 102))
(check-equal? (image-ranges c1) '((101 . 102)))
(check-equal? (image-total c1) 2)

;; ---- fill / offset ---------------------------------------------------------

(define f1 (image-fill-range i2 150 160 255))
(check-equal? (image-ranges f1) '((100 . 100) (150 . 160) (200 . 200)))
(check-equal? (image-ref f1 155) 255)

;; Fill adjacent to an existing run coalesces.
(define f2 (image-fill-range i2 101 199 0))
(check-equal? (image-ranges f2) '((100 . 200)))

;; Offset shifts everything; out-of-range raises a keyed error.
(check-equal? (image-ranges (image-offset i2 16)) '((116 . 116) (216 . 216)))
(check-exn exn:fail:bitsmith? (lambda () (image-offset i2 -101)))
(check-exn exn:fail:bitsmith? (lambda () (image-offset i2 4294967200)))

;; ---- gaps / segments / bounds ----------------------------------------------

(define g1 (img '(0 1 2 3) '(8000 4))) ; 0..2, 8000..8000
(check-equal? (image-gaps g1) (list (hasheq 'start 3 'end 7999 'size 7997)))
(check-equal? (image-segments g1)
              (list (hasheq 'kind "data" 'start 0 'end 2 'size 3)
                    (hasheq 'kind "data" 'start 8000 'end 8000 'size 1)))
(define-values (lo hi) (image-bounds g1))
(check-equal? lo 0)
(check-equal? hi 8000)
(check-equal? (image-span g1) 8001)
(check-equal? (image-total g1) 4)

;; No gaps when ranges touch.
(check-equal? (image-gaps i1) '())

;; ---- rows ------------------------------------------------------------------

(define-values (rows rows-truncated) (image-rows g1))
(check-false rows-truncated)
(check-equal? (map car rows) '(0 8000))
(check-equal? (vector->list (cdr (car rows)))
              '(1 2 3 #f #f #f #f #f #f #f #f #f #f #f #f #f))

;; A run starting mid-row fills the right cells.
(define-values (rows2 t2) (image-rows (img '(3 9 9 9))))
(check-false t2)
(check-equal? (map car rows2) '(0))
(check-equal? (vector->list (cdr (car rows2)))
              '(#f #f #f 9 9 9 #f #f #f #f #f #f #f #f #f #f))

;; Rows spanning two runs merge cells from both.
(define-values (rows3 t3) (image-rows (img '(0 1 2) '(16 3 4))))
(check-equal? (map car rows3) '(0 16))
(check-equal? (vector->list (cdr (car rows3))) '(1 2 #f #f #f #f #f #f #f #f #f #f #f #f #f #f))

;; Row limit reports truncation honestly (17 bytes -> two rows).
(define-values (limited truncated?)
  (image-rows (img '(0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17)) 16 #:limit 1))
(check-equal? truncated? #t)
(check-equal? (length limited) 1)
(check-equal? (vector->list (cdr (car limited)))
              (for/list ([i 16]) (add1 i)))

;; ---- diff ------------------------------------------------------------------

(define d-before (img '(100 1 2 3) '(200 4)))
(define d-after (img '(100 1 9 3) '(300 5)))
(define-values (added removed changed changes) (image-diff d-before d-after))
(check-equal? added 1)
(check-equal? removed 1)
(check-equal? changed 1)
(check-equal? changes
              (list (list "~ " 101 2 9)
                    (list "- " 200 4 'null)
                    (list "+ " 300 'null 5)))

;; Cap keeps counts complete while trimming the visible list.
(define-values (a2 rm2 ch2 changes2)
  (image-diff d-before
              (image-union d-before (img '(500 1) '(501 2) '(502 3)))
              2))
(check-equal? a2 3)
(check-equal? (length changes2) 2)

;; ---- union + overlap -------------------------------------------------------

(define fbl (img '(0 1 2 3)))
(define app (img '(16 9 9)))
(check-false (image-overlap-at fbl app))
(check-equal? (image-ranges (image-union fbl app)) '((0 . 2) (16 . 17)))

(define colliding (img '(2 9)))
(check-equal? (image-overlap-at fbl colliding) 2)

;; ---- error keys ------------------------------------------------------------

(check-exn exn:fail:bitsmith? (lambda () (image-fill-range i2 0 1048576 0))) ; 1048577 bytes
(check-exn exn:fail:bitsmith? (lambda () (image-set-run i0 -1 (bytes 1))))
