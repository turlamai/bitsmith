#lang racket/base

;; Memory-image model: an immutable, sorted, coalesced list of runs
;; ((start . bytes) ...), disjoint, addresses unsigned 32-bit.
;;
;; Semantics pinned by the design contract:
;;   - overlapping supplied records resolve last-wins at load time
;;   - a gap is missing information, never 0xFF
;;   - a populated byte equal to 0xFF is explicit erased-flash data; the
;;     segment map reports populated ranges and gaps only, the byte views
;;     style the 0xFF value itself
;;
;; All operations return fresh images; nothing mutates.

(require racket/list
         racket/match)

(provide (struct-out image)
         exn:fail:bitsmith-data
         empty-image
         image-total
         image-bounds
         image-span
         image-ref
         image-set-run
         image-fill-range
         image-remove-range
         image-crop
         image-offset
         image-union
         image-overlap-at
         image-ranges
         image-gaps
         image-segments
         image-rows
         image-diff
         exn:fail:bitsmith?
         exn:fail:bitsmith-key
         raise-bitsmith-error)

;; Errors carry a stable key plus optional data so the API layer can
;; localize the message (and interpolate values like the offending address).
;; Inherits exn:fail so generic handlers and check-exn see a normal failure.
(struct exn:fail:bitsmith exn:fail (key data) #:transparent)
(define (raise-bitsmith-error key [data (hasheq)])
  (raise (exn:fail:bitsmith "bitsmith engine error" (current-continuation-marks) key data)))

(struct image (runs) #:transparent)

(define empty-image (image '()))

(define (run-end run) (+ (car run) (bytes-length (cdr run)) -1))

;; ---- construction ----------------------------------------------------------

(define (coalesce runs)
  ;; Merge contiguous runs; assumes sorted and disjoint.
  (let loop ([runs runs] [out '()])
    (match runs
      ['() (reverse out)]
      [(cons r rest)
       (match out
         [(cons prev prev-rest)
          #:when (= (car r) (add1 (run-end prev)))
          (loop rest (cons (cons (car prev) (bytes-append (cdr prev) (cdr r)))
                           prev-rest))]
         [_ (loop rest (cons r out))])])))

(define (image-set-run img start bs)
  ;; Last-wins insertion: overlapping parts of existing runs are trimmed.
  ;; Only the first overlapping run can have a head fragment (runs are
  ;; sorted and disjoint); later overlaps contribute tail fragments only.
  (unless (<= 0 start 4294967295)
    (raise-bitsmith-error 'err-address-out-of-range))
  (define new-end (+ start (bytes-length bs) -1))
  (let loop ([runs (image-runs img)] [out '()] [tails '()])
    (match runs
      ['() (image (coalesce (append (reverse out)
                                    (list (cons start bs))
                                    (reverse tails))))]
      [(cons r rest)
       (define rend (run-end r))
       (cond
         [(< rend start)
          ;; Entirely before the new run: keep and continue.
          (loop rest (cons r out) tails)]
         [(> (car r) new-end)
          ;; Begins after the new run ends: nothing further overlaps.
          (image (coalesce (append (reverse out)
                                   (list (cons start bs))
                                   (reverse tails)
                                   runs)))]
         [else
          ;; Overlaps r: keep non-overlapping fragments, continue scanning
          ;; — later runs may overlap the new run too.
          (define head
            (and (< (car r) start)
                 (cons (car r) (subbytes (cdr r) 0 (- start (car r))))))
          (define tail
            (and (> rend new-end)
                 (cons (+ new-end 1) (subbytes (cdr r) (- (+ new-end 1) (car r))))))
          (loop rest
                (if head (cons head out) out)
                (if tail (cons tail tails) tails))])])))

(define (image-fill-range img start end value)
  (define n (+ (- end start) 1))
  (when (or (<= n 0) (> n 1048576))
    (raise-bitsmith-error 'err-range-too-large))
  (image-set-run img start (make-bytes n value)))

(define (image-remove-range img start end)
  ;; Accumulate descending (newest first) and reverse once at the end; a
  ;; trimmed run pushes its tail (high addresses) before its head so the
  ;; reversed order stays ascending.
  (let loop ([runs (image-runs img)] [out '()])
    (match runs
      ['() (image (coalesce (reverse out)))]
      [(cons r rest)
       (define rend (run-end r))
       (cond
         ;; Fully outside [start, end]: keep.
         [(or (< rend start) (> (car r) end))
          (loop rest (cons r out))]
         [else
          (define head (and (< (car r) start)
                            (cons (car r) (subbytes (cdr r) 0 (- start (car r))))))
          (define tail (and (> rend end)
                            (cons (+ end 1) (subbytes (cdr r) (- (+ end 1) (car r))))))
          (loop rest
                (append (if tail (list tail) '())
                        (if head (list head) '())
                        out))])])))

(define (image-crop img start end)
  (image-remove-range (image-remove-range img 0 (sub1 start)) (+ end 1) 4294967295))

(define (image-offset img delta)
  (define runs
    (for/list ([run (in-list (image-runs img))])
      (define start (+ (car run) delta))
      (when (or (negative? start) (> (+ (run-end run) delta) 4294967295))
        (raise-bitsmith-error 'err-relocation-out-of-range))
      (cons start (cdr run))))
  (image runs))

;; ---- queries ---------------------------------------------------------------

(define (image-ref img addr)
  (let loop ([runs (image-runs img)])
    (match runs
      ['() #f]
      [(cons r rest)
       (if (and (>= addr (car r)) (<= addr (run-end r)))
           (bytes-ref (cdr r) (- addr (car r)))
           (loop rest))])))

;; Coalesced populated ranges as (start . end-inclusive).
(define (image-ranges img)
  (map (lambda (run) (cons (car run) (run-end run))) (image-runs img)))

(define (image-bounds img)
  (define ranges (image-ranges img))
  (if (null? ranges)
      (values #f #f)
      (values (car (car ranges)) (cdr (car (reverse ranges))))))

;; Populated span: first to last populated byte, holes included.
(define (image-span img)
  (define-values (lo hi) (image-bounds img))
  (if lo (+ (- hi lo) 1) 0))

(define (image-total img)
  (for/fold ([n 0]) ([run (in-list (image-runs img))])
    (+ n (bytes-length (cdr run)))))

(define (image-gaps img)
  ;; Unmapped ranges BETWEEN populated runs.
  (define ranges (image-ranges img))
  (for/list ([r ranges]
             [next (cdr ranges)]
             #:when (> (car next) (add1 (cdr r))))
    (hasheq 'start (add1 (cdr r)) 'end (sub1 (car next))
            'size (- (car next) (cdr r) 1))))

(define (image-segments img)
  ;; Data segments: populated ranges. kind stays 'data; explicit-0xFF is a
  ;; byte-value property, not a segment boundary (contract: populated
  ;; ranges and unmapped gaps remain distinct).
  (for/list ([r (in-list (image-ranges img))])
    (hasheq 'kind "data" 'start (car r) 'end (cdr r)
            'size (+ (- (cdr r) (car r)) 1))))

;; 16-byte rows containing at least one populated byte, ascending.
;; #:limit caps the returned list; the second result says whether rows
;; were dropped. Returns (values (listof (cons row-start cells)) truncated?)
;; with cells a (vectorof (or/c byte #f)).
(define (image-rows img [row-size 16] #:limit [limit #f])
  (define table (make-hash))
  (for ([run (in-list (image-runs img))])
    (for ([i (in-naturals (car run))] [b (in-bytes (cdr run))])
      (define row (* (quotient i row-size) row-size))
      (define cells (hash-ref! table row (lambda () (make-vector row-size #f))))
      (vector-set! cells (- i row) b)))
  (define keys (sort (hash-keys table) <))
  (define rows
    (for/list ([row (in-list (if limit (take keys (min limit (length keys))) keys))])
      (cons row (hash-ref table row))))
  (values rows (and limit (> (length keys) limit))))

;; ---- diff ------------------------------------------------------------------

;; Flat (addr . byte) stream, ascending. Bounded by the operations layer to
;; 1 MiB previews, so materialising the list is acceptable here.
(define (byte-list img)
  (append*
   (for/list ([run (in-list (image-runs img))])
     (for/list ([i (in-naturals (car run))] [b (in-bytes (cdr run))])
       (cons i b)))))

;; Ordered two-pointer walk. Returns
;; (values added removed changed changes) where each change is
;; (list mark address before-byte-or-'null after-byte-or-'null) with mark
;; one of "+ " "- " "~ "; the list is capped at cap entries while counts
;; stay complete.
(define (image-diff before after [cap 12])
  (let walk ([a (byte-list before)] [b (byte-list after)]
             [added 0] [removed 0] [changed 0] [changes '()])
    (cond
      [(and (null? a) (null? b))
       (values added removed changed (reverse changes))]
      [(null? a)
       (walk a (cdr b) (add1 added) removed changed
             (collect "+ " (car b) 'null (cdr (car b)) changes cap))]
      [(null? b)
       (walk (cdr a) b added (add1 removed) changed
             (collect "- " (car a) (cdr (car a)) 'null changes cap))]
      [else
       (define av (car a))
       (define bv (car b))
       (cond
         [(< (car av) (car bv))
          (walk (cdr a) b added (add1 removed) changed
                (collect "- " av (cdr av) 'null changes cap))]
         [(> (car av) (car bv))
          (walk a (cdr b) (add1 added) removed changed
                (collect "+ " bv 'null (cdr bv) changes cap))]
         [else
          (if (= (cdr av) (cdr bv))
              (walk (cdr a) (cdr b) added removed changed changes)
              (walk (cdr a) (cdr b) added removed (add1 changed)
                    (collect "~ " av (cdr av) (cdr bv) changes cap)))])])))

(define (collect mark pair from to changes cap)
  (if (< (length changes) cap)
      (cons (list mark (car pair) from to) changes)
      changes))

;; ---- union -----------------------------------------------------------------

;; Overlay wins on overlap (last-wins); overlap detection is a separate
;; explicit check so the merge operation can block instead of overwriting.
(define (image-union base overlay)
  (let loop ([runs (image-runs overlay)] [img base])
    (if (null? runs)
        img
        (loop (cdr runs)
              (image-set-run img (car (car runs)) (cdr (car runs)))))))

(define (image-overlap-at a b)
  (let walk ([pa (byte-list a)] [pb (byte-list b)])
    (cond
      [(or (null? pa) (null? pb)) #f]
      [(= (car (car pa)) (car (car pb))) (car (car pa))]
      [(< (car (car pa)) (car (car pb))) (walk (cdr pa) pb)]
      [else (walk pa (cdr pb))])))
