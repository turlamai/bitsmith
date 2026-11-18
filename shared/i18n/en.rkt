#lang racket/base
;; English strings. Keys are stable identifiers; UI truth = design/prototype/.
(provide strings)

(define strings
  (hasheq 'app-name "Bitsmith"
          'tagline "Understand and master firmware images"))
