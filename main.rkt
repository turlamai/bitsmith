#lang racket/base

;; Bitsmith desktop entry: glaze runs the shared engine behind the system
;; WebView. Window behavior stays here; product logic stays in
;; shared/engine/ (see AGENTS.md ownership routing).

(require glaze
         racket/runtime-path
         "shared/engine/main.rkt")

(define-runtime-path public "public")

(module+ main
  (run-app #:public-dir public
           #:api api
           #:title "Bitsmith"
           #:width 1280
           #:height 800
           #:app-id bitsmith-app-id
           #:window-state #t))

(provide api bitsmith-app-id public)
