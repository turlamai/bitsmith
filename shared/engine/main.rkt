#lang racket/base
;; ImageBench engine — firmware image model, parse/serialize, operations.
;; Stub: schema routes land here via glaze.rktd (schema-binding: api).
;; Format matrix and operation list live in ../spec.md.
(provide api)

(define (api msg)
  (hasheq 'ok #t 'stub "imagebench-engine"))

(module+ test
  (require rackunit)
  (check-equal? (hash-ref (api (hasheq)) 'ok) #t))
