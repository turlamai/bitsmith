#lang racket/base

;; Native UI acceptance: opens the real system WebView, asserts the
;; workspace contract through the engine API, captures a PNG, closes.
;; Pattern follows the glaze taskboard acceptance script.

(require racket/file
         json
         racket/runtime-path
         glaze
         "shared/engine/main.rkt")

(define-runtime-path public "public")

(define verdicts '())
(define (record! key value)
  (set! verdicts (cons (cons key value) verdicts)))

;; Engine assertions first (no display needed): the sample workspace
;; contract from shared/spec.md.
(record! 'sample-stats
         (let* ([ws (sample-workspace)]
                [summary (workspace-summary "en" ws)])
           (and (equal? (hash-ref summary 'kind) "intel")
                (= (hash-ref (hash-ref summary 'stats) 'valid) 7)
                (= (hash-ref (hash-ref summary 'stats) 'records) 8))))

;; Native UI pass: real window, real load, real screenshot.
(define deadline-ms 20000)
(define screenshot #f)

(define-values (_kind stop)
  (run-app #:public-dir public
           #:api api
           #:title "Bitsmith"
           #:width 1280
           #:height 800
           #:window-state #f
           #:on-ready
           (lambda (wv url)
             (define deadline (+ (current-inexact-milliseconds) deadline-ms))
             (define loaded?
               (let loop ()
                 (cond
                   [(>= (current-inexact-milliseconds) deadline) #f]
                   [(and (webview-title wv)
                         (regexp-match? "bitsmith" (webview-title wv))) #t]
                   [else (sleep 0.1) (loop)])))
             (printf "[verify] title = ~a url = ~a\n" (webview-title wv) (webview-url wv))
             (when loaded? (sleep 1.0))
             (define shot (and loaded? (webview-capture! wv)))
             (set! screenshot shot)
             (record! 'page-loaded loaded?)
             (record! 'url (regexp-match? #rx"records\\.html$" (webview-url wv)))
             (record! 'capture (and shot (file-exists? shot) (> (file-size shot) 0)))
             ;; Walk the remaining views; each must commit with a Bitsmith title.
             (define (visit page expected)
               (webview-navigate wv (string-append base-url page))
               (let loop ([deadline (+ (current-inexact-milliseconds) 8000)])
                 (cond
                   [(and (webview-title wv) (regexp-match? expected (webview-title wv))) #t]
                   [(>= (current-inexact-milliseconds) deadline) #f]
                   [else (sleep 0.1) (loop deadline)])))
             (define base-url
               (substring (webview-url wv) 0 (- (string-length (webview-url wv))
                                                (string-length "records.html"))))
             (record! 'image-view (visit "image.html" "Image view"))
             (printf "[verify] image-title = ~a\n" (webview-title wv))
             (sleep 0.6)
             (define image-shot (webview-capture! wv))
             (record! 'image-capture (and image-shot (file-exists? image-shot) (> (file-size image-shot) 0)))
             (record! 'operations-view (visit "operations.html" "Operations"))
             (sleep 0.6)
             (define ops-shot (webview-capture! wv))
             (record! 'ops-capture (and ops-shot (file-exists? ops-shot) (> (file-size ops-shot) 0)))
             (record! 'learn-view (visit "learn.html" "Learn"))
             (sleep 0.6)
             (define learn-shot (webview-capture! wv))
             (record! 'learn-capture (and learn-shot (file-exists? learn-shot) (> (file-size learn-shot) 0)))
             (when image-shot (printf "[verify] image-screenshot = ~a\n" image-shot))
             (when ops-shot (printf "[verify] ops-screenshot = ~a\n" ops-shot))
             ;; The Patch card through its #patch link; the title does not
             ;; change on this hop, so give the page time to settle.
             (webview-navigate wv (string-append base-url "operations.html#patch"))
             (sleep 1.2)
             (define patch-shot (webview-capture! wv))
             (record! 'patch-capture (and patch-shot (file-exists? patch-shot) (> (file-size patch-shot) 0)))
             (when patch-shot (printf "[verify] patch-screenshot = ~a\n" patch-shot))
             (when learn-shot (printf "[verify] learn-screenshot = ~a\n" learn-shot))
             (webview-close wv))))

(void (stop))

(for ([verdict (in-list (reverse verdicts))])
  (printf "[verify] ~a = ~a\n" (car verdict) (cdr verdict)))
(when screenshot
  (printf "[verify] screenshot = ~a\n" screenshot))

(unless (and (pair? verdicts) (andmap cdr verdicts))
  (eprintf "[verify] native UI verification failed\n")
  (exit 1))

(displayln "[verify] ALL PASS")
