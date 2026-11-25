#lang racket/base

;; Bitsmith engine — the typed API surface (glaze.rktd schema-module) and
;; the in-memory workspace session.
;;
;; One workspace per app run: name, sniffed kind, parsed records, byte-map
;; image and a revision counter that increments on every applied commit.
;; Every string-bearing route takes `lang` ("en" | "zh"); string tables live
;; in ../i18n. Engine errors carry stable keys and localize here.
;;
;; Scope and format matrix: ../spec.md. Sample set: synthetic, checksum
;; verified (../spec.md), never employer material.

(require glaze
         glaze/api-macros
         glaze/types
         racket/file
         racket/format
         racket/list
         racket/match
         racket/path
         racket/set
         racket/string
         racket/symbol
         "../i18n/en.rkt"
         (prefix-in zh: "../i18n/zh.rkt")
         "crc.rkt"
         "detect.rkt"
         "hex.rkt"
         "image.rkt"
         "ops.rkt"
         "srec.rkt"
         "serialize.rkt"
         "updater.rkt")

(provide api
         bitsmith-app-id
         app-version
         workspace-summary
         sample-workspace
         make-workspace-from-bytes
         reset-workspace)

(define bitsmith-app-id "com.turlamai.bitsmith")
(define app-version "0.1.0")

;; ---- limits ----------------------------------------------------------------

(define open-file-limit (* 4 1024 1024))       ; 4 MiB open bound (preview build)
(define records-view-cap 5000)                 ; rows rendered in the record table
(define records-diff-cap 20000)                ; canonical lines compared for diffs
(define bin-save-limit (* 16 1024 1024))       ; materialised BIN bound on save

;; ---- string tables ----------------------------------------------------------

(define en-strings strings)
(define zh-strings zh:strings)

(define (strings-for lang)
  (if (equal? lang "zh") zh-strings en-strings))

(define (s lang key)
  (hash-ref (strings-for lang) key (hash-ref en-strings key (symbol->string key))))

(define (norm-lang lang)
  (if (equal? lang "zh") "zh" "en"))

(define (hex-addr n)
  (string-upcase (~a (number->string n 16) #:min-width 8 #:pad-string "0")))

;; Localize a bitsmith error; interpolate known data (address).
(define (error-text lang e)
  (define key (exn:fail:bitsmith-key e))
  (define data (exn:fail:bitsmith-data e))
  (cond
    [(and (equal? key 'err-crc-unmapped-at) (hash-has-key? data 'address))
     (string-append (s lang key) " (0x" (hex-addr (hash-ref data 'address)) ")")]
    [(and (equal? key 'err-merge-overlap) (hash-has-key? data 'address))
     (string-append (s lang key) " (0x" (hex-addr (hash-ref data 'address)) ")")]
    [else (s lang key)]))

;; ---- workspace session ------------------------------------------------------

(struct workspace
  (name ext kind sample? image records revision elf)
  #:transparent)

(define empty-workspace (workspace "No file open" #f 'none #t empty-image '() 0 #f))

;; Boot with the supplied sample loaded — the prototype's designed
;; first-run state (records view shows the verified sample immediately).
;; Initialized lazily: sample-workspace is defined below.
(define state-box (box #f))
(define state-lock (make-semaphore 1))

(define (current)
  (or (unbox state-box)
      (let ([ws (sample-workspace)])
        (set-box! state-box ws)
        ws)))

(define (update! f)
  (call-with-semaphore state-lock
                       (lambda ()
                         (define next (f (current)))
                         (set-box! state-box next)
                         next)))

(define (bump ws)
  (struct-copy workspace ws [revision (add1 (workspace-revision ws))]))

(define (reset-workspace)
  (update! (lambda (_) (sample-workspace))))

;; ---- sample ----------------------------------------------------------------

(define sample-lines
  (list
   ":020000040800F2"
   ":200000000010020009590108FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7B"
   ":10001000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0"
   ":088000000050002001598A081C"
   ":088010002DE9F0470DF080F8A6"
   ":109FF000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF71"
   ":0480200048B1084700"
   ":00000001FF"))

;; Build the byte map from OK data records, last-wins on overlap (contract).
;; Intel data records are type 0; S-record data records are S1/S2/S3.
(define (records->image records type-ok?)
  (for/fold ([img empty-image])
            ([record (in-list records)]
             #:when (and (hash-ref record 'ok) (type-ok? (hash-ref record 'type))))
    (image-set-run img
                   (hash-ref record 'absolute)
                   (list->bytes (hash-ref record 'data)))))

(define (sample-workspace)
  (define records (parse-intel-hex (string-join sample-lines "\n")))
  (workspace "FBL_APP_combined.dat" "dat" 'intel #t
             (records->image records (lambda (t) (equal? t 0))) records 0 #f))

;; ---- load path --------------------------------------------------------------

(define (make-workspace-from-bytes name data)
  (when (> (bytes-length data) open-file-limit)
    (raise-bitsmith-error 'err-file-too-large))
  (define sniff (sniff-bytes (subbytes data 0 (min 4096 (bytes-length data)))))
  (define kind (hash-ref sniff 'kind))
  (define ext
    (let ([m (regexp-match #rx"\\.([^.]+)$" name)])
      (and m (list-ref m 1))))
  (case kind
    [(intel)
     (define records (parse-intel-hex (bytes->string/utf-8 data)))
     (unless (pair? records) (raise-bitsmith-error 'err-no-valid-records))
     (unless (pair? (filter (lambda (r) (and (hash-ref r 'ok) (equal? (hash-ref r 'type) 0))) records))
       (raise-bitsmith-error 'err-no-valid-records))
     (workspace name ext 'intel #f (records->image records (lambda (t) (equal? t 0))) records 1 #f)]
    [(srec)
     (define records (parse-srec (bytes->string/utf-8 data)))
     (unless (pair? records) (raise-bitsmith-error 'err-no-valid-records))
     (unless (pair? (filter (lambda (r) (and (hash-ref r 'ok)
                                             (member (hash-ref r 'type) '("1" "2" "3"))))
                            records))
       (raise-bitsmith-error 'err-no-valid-records))
     (workspace name ext 'srec #f
                (records->image records (lambda (t) (member t '("1" "2" "3"))))
                records 1 #f)]
    [(elf)
     (define summary (elf-summary data))
     (workspace name ext 'elf #f empty-image '() 1 summary)]
    [(bin)
     ;; Base assumption: first byte is 0x08000000 unless the file is empty.
     (define img (if (> (bytes-length data) 0)
                     (image-set-run empty-image 134217728 data)
                     empty-image))
     (workspace name ext 'bin #f img '() 1 #f)]
    [else (raise-bitsmith-error 'err-unreadable)]))

;; ---- response shapes ---------------------------------------------------------

(define (workspace-summary lang [ws (current)])
  (define kind (workspace-kind ws))
  (define img (workspace-image ws))
  (define loaded (not (equal? kind 'none)))
  (define-values (lo hi) (image-bounds img))
  (define valid
    (length (filter (lambda (r) (hash-ref r 'ok #f)) (workspace-records ws))))
  (hasheq
   'loaded loaded
   'name (workspace-name ws)
   'ext (or (workspace-ext ws) 'null)
   'kind (if (eq? kind 'none) 'null (symbol->string kind))
   'format-label (case kind
                   [(intel) (s lang 'format-intel)]
                   [(srec) (s lang 'format-srec)]
                   [(bin) (s lang 'format-bin)]
                   [(elf) (s lang 'format-elf)]
                   [else (s lang 'format-bin)])
   'sample (workspace-sample? ws)
   'revision (workspace-revision ws)
   'stats (hasheq
           'records (length (workspace-records ws))
           'valid valid
           'data-bytes (image-total img)
           'span (image-span img)
           'min (or lo 'null)
           'max (or hi 'null))
   'segments (if loaded (image-segments img) '())
   'gaps (if loaded (image-gaps img) '())
   'elf (or (workspace-elf ws) 'null)
   'strings (strings-for lang)))

;; ---- parameter parsing (forms send display strings; engine validates) ------

(define (param-byte text)
  (define n (parse-address-text text))
  (unless (<= n 255) (raise-bitsmith-error 'err-value-out-of-range))
  n)

(define (param-policy text)
  (cond
    [(equal? text "reject") 'reject]
    [(equal? text "0x00") '00]
    [else 'FF]))

(define preset-by-id
  (hasheq "CRC-32/MPEG-2" 'mpeg2
          "CRC-32/ISO-HDLC" 'iso-hdlc
          "CRC-16/XMODEM" 'xmodem
          "sum8" 'sum8))

;; JSON body keys arrive as symbols (jsexpr convention).
(define (op-params op raw)
  (define (addr key) (parse-address-text (hash-ref raw key)))
  (case op
    [(fill)
     (hasheq 'start (addr 'start) 'end (addr 'end)
             'value (param-byte (hash-ref raw 'value)))]
    [(patch)
     (hasheq 'address (addr 'address)
             'bytes (parse-bytes-text (hash-ref raw 'bytes)))]
    [(pad)
     (hasheq 'alignment (addr 'alignment) 'value (param-byte (hash-ref raw 'value)))]
    [(offset) (hasheq 'delta (parse-signed-text (hash-ref raw 'delta)))]
    [(crop) (hasheq 'start (addr 'start) 'end (addr 'end))]
    [(merge) (hasheq 'base (addr 'base))]
    [(convert)
     (hasheq 'target (string->symbol (hash-ref raw 'target))
             'width (string->symbol (hash-ref raw 'width "S3"))
             'line (string->number (hash-ref raw 'line "16"))
             'value (param-byte (hash-ref raw 'value "0xFF"))
             'base (parse-address-text (hash-ref raw 'base "0x08000000")))]
    [(crc)
     (define preset-id (hash-ref preset-by-id (hash-ref raw 'preset) #f))
     (unless preset-id (raise-bitsmith-error 'err-unknown-preset))
     (hasheq 'preset preset-id 'start (addr 'start) 'end (addr 'end)
             'value (param-policy (hash-ref raw 'value)))]
    [else (raise-bitsmith-error 'err-unknown-op)]))

;; ---- preview ----------------------------------------------------------------

(define (preview-response lang op raw)
  (define ws (current))
  (when (equal? (workspace-kind ws) 'none)
    (raise-bitsmith-error 'err-empty-image))
  (define params (op-params op raw))
  ;; CRC is read-only: nothing to apply, nothing to diff.
  (define-values (after note-key extra)
    (if (equal? op 'crc)
        (values (workspace-image ws) 'crc-read-only (hasheq))
        (op-apply op (workspace-image ws) params)))
  (define-values (added removed changed changes)
    (image-diff (workspace-image ws) after 12))
  (define-values (before-lines before-count)
    (canonical-lines (workspace-image ws) op params))
  (define-values (after-lines after-count)
    (canonical-lines after op params))
  (define record-diff
    (if (and (< before-count records-diff-cap) (< after-count records-diff-cap))
        (lines-diff before-lines after-lines)
        (hasheq 'removed 0 'added 0 'lines '() 'skipped #t)))
  (define crc (if (equal? op 'crc) (op-crc (workspace-image ws) params) #f))
  (hasheq
   'ok #t
   'blocked #f
   'revision (workspace-revision ws)
   'note (s lang note-key)
   'added added
   'removed removed
   'changed changed
   'changes changes
   'before-count before-count
   'after-count after-count
   'record-diff record-diff
   'after-segments (image-segments after)
   'after-gaps (image-gaps after)
   'output (preview-output lang op params after)
   'crc (if crc
            (hasheq 'value (hash-ref crc 'value)
                    'bits (hash-ref crc 'bits)
                    'count (hash-ref crc 'count)
                    'gaps (hash-ref crc 'gaps)
                    'poly (hash-ref crc 'poly)
                    'init (hash-ref crc 'init)
                    'xor (hash-ref crc 'xor)
                    'reflect (hash-ref crc 'reflect)
                    'label (hash-ref crc 'label)
                    'note (s lang (hash-ref crc 'note-key))
                    'read-only (s lang 'crc-read-only))
            'null)))

;; Canonical lines per view: convert previews its own target format,
;; everything else compares canonical Intel HEX.
(define (canonical-lines img op params)
  (cond
    [(and (equal? op 'convert) (equal? (hash-ref params 'target) 'SREC))
     (define lines (image->srec-lines img (hash-ref params 'width) (hash-ref params 'line)))
     (values lines (length lines))]
    [else
     (define lines (image->intel-lines img 16))
     (values lines (length lines))]))

(define (lines-diff before after)
  (define before-set (list->set before))
  (define after-set (list->set after))
  (define removed (for/list ([l (in-list before)] #:unless (set-member? after-set l)) l))
  (define added (for/list ([l (in-list after)] #:unless (set-member? before-set l)) l))
  (hasheq 'removed (length removed)
          'added (length added)
          'lines (append (take removed (min 4 (length removed)))
                         (take added (min 4 (length added))))
          'skipped #f))

(define (preview-output lang op params after)
  (case op
    [(convert)
     (case (hash-ref params 'target)
       [(BIN)
        (string-append
         "BIN base 0x" (hex-addr (hash-ref params 'base))
         " · " (~a (image-total after)) " bytes\n"
         (image->bin-hex-preview after (hash-ref params 'base) (hash-ref params 'value)))]
       [else
        (define lines
          (if (equal? (hash-ref params 'target) 'SREC)
              (image->srec-lines after (hash-ref params 'width) (hash-ref params 'line))
              (image->intel-lines after 16)))
        (string-append (string-join (take lines (min 8 (length lines))) "\n")
                       (if (> (length lines) 8)
                           (string-append "\n… " (~a (length lines)) " generated records total")
                           ""))])]
    [else #f]))

;; ---- error guard ------------------------------------------------------------

(define (guard lang thunk)
  (with-handlers
      ([exn:fail:bitsmith?
        (lambda (e)
          (hasheq 'ok #f 'blocked #t
                  'error-key (exn:fail:bitsmith-key e)
                  'error (error-text lang e)))])
    (thunk)))

;; ---- apply helpers ---------------------------------------------------------

(define (apply-kind op params kind)
  (if (equal? op 'convert)
      (case (hash-ref params 'target)
        [(BIN) 'bin]
        [(SREC) 'srec]
        [else 'intel])
      kind))

(define (apply-phrase l op params)
  (case op
    [(convert)
     (case (hash-ref params 'target)
       [(BIN) (s l 'phrase-bin-materialised)]
       [else (s l 'phrase-conversion-applied)])]
    [else (s l 'phrase-applied)]))

(define (save-payload ws l)
  (case (workspace-kind ws)
    [(intel)
     (values (string-join (image->intel-lines (workspace-image ws) 16) "\n")
             "bitsmith.hex"
             (list (list (s l 'filter-hex) "*.hex" "*.ihex")))]
    [(srec)
     (values (string-join (image->srec-lines (workspace-image ws) 'S3 16) "\n")
             "bitsmith.srec"
             (list (list (s l 'filter-srec) "*.srec" "*.s19" "*.mot")))]
    [(bin)
     (define-values (lo hi) (image-bounds (workspace-image ws)))
     (when (or (not hi) (> (image-span (workspace-image ws)) bin-save-limit))
       (raise-bitsmith-error 'err-bin-too-large))
     ;; A BIN save carries no base metadata: materialise from the first
     ;; populated byte (the base assumption is surfaced in the UI).
     (values (image->bin-bytes (workspace-image ws) (or lo 0) 255)
             "bitsmith.bin"
             (list (list (s l 'filter-bin) "*.bin")))]
    [else (raise-bitsmith-error 'err-empty-image)]))

;; Learn: live Intel HEX checksum arithmetic, step by step.
(define (learn-checksum-response lang line)
  (define raw (string-trim line))
  (unless (regexp-match? #rx"^:(?:[0-9a-fA-F]{2}){5,}$" raw)
    (hasheq 'ok #t 'valid #f 'reason (s lang 'learn-input-error)))
  (define bytes (hex-pairs (substring raw 1)))
  (define count (list-ref bytes 0))
  (unless (= (length bytes) (+ count 5))
    (hasheq 'ok #t 'valid #f 'reason (s lang 'learn-count-mismatch)))
  (define payload (take bytes (+ 4 count)))
  (define stored (list-ref bytes (+ 4 count)))
  (define sum (foldl + 0 payload))
  (define low (remainder sum 256))
  (define expected (remainder (- 256 low) 256))
  (define pass? (= stored expected))
  (hasheq 'ok #t 'valid #t 'pass pass?
          'stored stored 'expected expected 'sum sum 'low low
          'steps (list (hasheq 'label (s lang 'learn-intel-step-1)
                               'value (string-join (map (lambda (b) (hex-str b 2)) payload) " + ")
                               'note (s lang 'learn-intel-step-1-note))
                       (hasheq 'label (s lang 'learn-intel-step-2)
                               'value (string-append "0x" (hex-str sum 2) " & FF = " (hex-str low 2))
                               'note (s lang 'learn-intel-step-2-note))
                       (hasheq 'label (s lang 'learn-intel-step-3)
                               'value (string-append "100 - " (hex-str low 2) " = " (hex-str expected 2))
                               'note (s lang 'learn-intel-step-3-note))
                       (hasheq 'label (s lang 'learn-intel-step-4)
                               'value (string-append (hex-str stored 2)
                                                     (if pass? " = " " ≠ ")
                                                     (hex-str expected 2))
                               'note (s lang 'learn-intel-step-4-note)))
          'verdict (if pass? (s lang 'learn-pass) (s lang 'learn-fail))))

;; ---- operation spec descriptors ----------------------------------------------
;; The frontend renders the parameter form from this; values come back as
;; display strings the engine validates.

(define (field-text key label default)
  (hasheq 'key (symbol->string key) 'label label 'kind "address" 'default default))

(define (field-select key label options default)
  (hasheq 'key (symbol->string key) 'label label 'kind "select" 'options options 'default default))

;; Free-form hexadecimal payload; `placeholder` is an example, not a value.
(define (field-bytes key label default placeholder)
  (hasheq 'key (symbol->string key) 'label label 'kind "bytes"
          'default default 'placeholder placeholder))

;; `help` replaces the generic range note under the form when the
;; operation's input rules differ (optional).
(define (op-spec lang id name-key desc-key badge fields [help #f])
  (hasheq
   'id (symbol->string id)
   'name (s lang name-key)
   'desc (s lang desc-key)
   'badge badge
   'help (and help (s lang help))
   'fields fields))

(define (ops-spec-response lang)
  (hasheq
   'ok #t
   'ops (list
         (op-spec lang 'fill 'op-fill-name 'op-fill-desc (s lang 'op-badge-edit)
                  (list (field-text 'start (s lang 'field-start) "0x08000020")
                        (field-text 'end (s lang 'field-end) "0x08007FFF")
                        (field-select 'value (s lang 'field-value) (list "0x00" "0xFF") "0xFF")))
         (op-spec lang 'patch 'op-patch-name 'op-patch-desc (s lang 'op-badge-edit)
                  (list (field-text 'address (s lang 'field-address) "0x08008010")
                        (field-bytes 'bytes (s lang 'field-bytes) "00 BF"
                                     (s lang 'field-bytes-placeholder)))
                  'field-help-patch)
         (op-spec lang 'pad 'op-pad-name 'op-pad-desc (s lang 'op-badge-edit)
                  (list (field-text 'alignment (s lang 'field-alignment) "0x1000")
                        (field-select 'value (s lang 'field-value) (list "0x00" "0xFF") "0xFF")))
         (op-spec lang 'offset 'op-offset-name 'op-offset-desc (s lang 'op-badge-edit)
                  (list (field-text 'delta (s lang 'field-delta) "0x8000")))
         (op-spec lang 'crop 'op-crop-name 'op-crop-desc (s lang 'op-badge-edit)
                  (list (field-text 'start (s lang 'field-start) "0x08008000")
                        (field-text 'end (s lang 'field-end) "0x08009FFF")))
         (op-spec lang 'merge 'op-merge-name 'op-merge-desc (s lang 'op-badge-edit)
                  (list (field-text 'base (s lang 'field-base) "0x08008000")))
         (op-spec lang 'convert 'op-convert-name 'op-convert-desc (s lang 'op-badge-edit)
                  (list (field-select 'target (s lang 'field-target) (list "HEX" "SREC" "BIN") "SREC")
                        (field-select 'width (s lang 'field-width) (list "S1" "S2" "S3") "S3")
                        (field-select 'line (s lang 'field-line) (list "16" "32") "16")
                        (field-select 'value (s lang 'field-value) (list "0x00" "0xFF") "0xFF")
                        (field-text 'base (s lang 'field-base) "0x08000000")))
         (op-spec lang 'crc 'op-crc-name 'op-crc-desc (s lang 'op-badge-read)
                  (list (field-select 'preset (s lang 'field-preset)
                                      (list "CRC-32/MPEG-2" "CRC-32/ISO-HDLC" "CRC-16/XMODEM" "sum8")
                                      "CRC-32/MPEG-2")
                        (field-text 'start (s lang 'field-start) "0x08008000")
                        (field-text 'end (s lang 'field-end) "0x08009FFF")
                        (field-select 'value (s lang 'field-value)
                                      (list "0xFF" "0x00" "reject") "0xFF"))))))

;; ---- routes -------------------------------------------------------------------
;; POST everywhere (invoke style), matching the family's bridge contract.

(define-api-routes api
  [(GET "api/health" #:returns (grecord "Health" "ok" GString
                                         "version" GString))
   (health)
   (hasheq 'ok #t 'version app-version)]

  [(POST "api/app/meta" #:returns GValue)
   (app-meta [lang GString "en"])
   (hasheq 'name (s (norm-lang lang) 'app-name) 'version app-version)]

  [(POST "api/i18n/strings" #:returns GValue)
   (i18n-strings [lang GString "en"])
   (strings-for (norm-lang lang))]

  [(POST "api/workspace/state" #:returns GValue)
   (workspace-state [lang GString "en"])
   (workspace-summary (norm-lang lang))]

  [(POST "api/records/view" #:returns GValue)
   (records-view [lang GString "en"])
   (guard (norm-lang lang) (lambda ()
     (define l (norm-lang lang))
     (define ws (current))
     (when (equal? (workspace-kind ws) 'none)
       (raise-bitsmith-error 'err-empty-image))
     (define records (workspace-records ws))
     (hasheq 'ok #t
             'records (take records (min records-view-cap (length records)))
             'truncated (> (length records) records-view-cap)
             'summary (workspace-summary l ws))))]

  [(POST "api/image/view" #:returns GValue)
   (image-view [lang GString "en"] [limit GInt64 8192])
   (guard (norm-lang lang) (lambda ()
     (define l (norm-lang lang))
     (define ws (current))
     (when (equal? (workspace-kind ws) 'none)
       (raise-bitsmith-error 'err-empty-image))
     (define-values (rows truncated) (image-rows (workspace-image ws) 16 #:limit limit))
     (hasheq 'ok #t
             'rows (map (lambda (row) (hasheq 'start (car row) 'cells (vector->list (cdr row)))) rows)
             'row-truncated truncated
             'summary (workspace-summary l ws))))]

  [(POST "api/ops/specs" #:returns GValue)
   (ops-specs [lang GString "en"])
   (ops-spec-response (norm-lang lang))]

  [(POST "api/ops/preview" #:returns GValue)
   (ops-preview [op GString] [params hash?] [lang GString "en"])
   (guard (norm-lang lang) (lambda ()
     (preview-response (norm-lang lang) (string->symbol op) params)))]

  [(POST "api/ops/apply" #:returns GValue)
   (ops-apply [op GString] [params hash?] [expectRevision GInt64 0] [lang GString "en"])
   (guard (norm-lang lang) (lambda ()
     (define l (norm-lang lang))
     (define op-id (string->symbol op))
     (define ws (current))
     (when (equal? (workspace-kind ws) 'none)
       (raise-bitsmith-error 'err-empty-image))
     (when (and (> expectRevision 0) (not (= expectRevision (workspace-revision ws))))
       (raise-bitsmith-error 'err-revision-conflict))
     (define parsed (op-params op-id params))
     ;; Compute outside the swap; commit atomically under the state lock.
     (define-values (after note-key extra) (op-apply op-id (workspace-image ws) parsed))
     (define next
       (bump
        (struct-copy workspace ws
                     [image after]
                     [kind (apply-kind op-id parsed (workspace-kind ws))]
                     ;; BIN conversion materialises gaps: record lines no
                     ;; longer describe the image.
                     [records (if (and (equal? op-id 'convert)
                                       (equal? (hash-ref parsed 'target) 'BIN))
                                  '()
                                  (workspace-records ws))])))
     (update! (lambda (_) next))
     (define fresh (current))
     (hasheq 'ok #t
             'revision (workspace-revision fresh)
             'phrase (apply-phrase l op-id parsed)
             'summary (workspace-summary l fresh))))]

  [(POST "api/workspace/reset" #:returns GValue)
   (workspace-reset [lang GString "en"])
   (guard (norm-lang lang) (lambda ()
     (define l (norm-lang lang))
     (reset-workspace)
     (hasheq 'ok #t 'phrase (s l 'phrase-sample-restored)
             'summary (workspace-summary l))))]

  [(POST "api/workspace/close" #:returns GValue)
   (workspace-close [lang GString "en"])
   (guard (norm-lang lang) (lambda ()
     (define l (norm-lang lang))
     (update! (lambda (_) empty-workspace))
     (hasheq 'ok #t 'phrase (s l 'phrase-file-closed)
             'summary (workspace-summary l))))]

  [(POST "api/workspace/open" #:returns GValue)
   (workspace-open [lang GString "en"])
   (guard (norm-lang lang) (lambda ()
     (define l (norm-lang lang))
     (unless (dialog-supported?) (raise-bitsmith-error 'err-unreadable))
     (define path
       (pick-file #:title (s l 'dialog-open-title)
                  #:filters (list (list (s l 'filter-hex) "*.hex" "*.ihex" "*.ihx")
                                  (list (s l 'filter-srec) "*.srec" "*.s19" "*.s28" "*.s37" "*.mot")
                                  (list (s l 'filter-bin) "*.bin" "*.dat" "*.img" "*.elf" "*.axf")
                                  (list (s l 'filter-all) "*"))))
     (unless path
       (hasheq 'ok #t 'cancelled #t 'phrase (s l 'phrase-open-cancelled)))
     (define data
       (with-handlers ([exn:fail? (lambda (_) (raise-bitsmith-error 'err-unreadable))])
         (file->bytes path)))
     (update! (lambda (_)
                (make-workspace-from-bytes
                 (path->string (file-name-from-path path)) data)))
     (hasheq 'ok #t 'cancelled #f 'phrase (s l 'phrase-loaded)
             'summary (workspace-summary l))))]

  [(POST "api/workspace/save" #:returns GValue)
   (workspace-save [lang GString "en"])
   (guard (norm-lang lang) (lambda ()
     (define l (norm-lang lang))
     (define ws (current))
     (when (equal? (workspace-kind ws) 'none)
       (raise-bitsmith-error 'err-empty-image))
     (when (equal? (workspace-kind ws) 'elf)
       (raise-bitsmith-error 'err-not-elf))
     (define-values (payload default-name filters)
       (save-payload ws l))
     (unless (dialog-supported?) (raise-bitsmith-error 'err-unreadable))
     (define path
       (save-file-dialog #:title (s l 'dialog-save-title)
                         #:default-name default-name
                         #:filters filters))
     (unless path
       (hasheq 'ok #t 'cancelled #t 'phrase (s l 'phrase-save-cancelled)))
     (with-handlers ([exn:fail? (lambda (_) (raise-bitsmith-error 'err-unreadable))])
       (call-with-output-file path
         (lambda (out)
           (if (bytes? payload)
               (write-bytes payload out)
               (display payload out)))
         #:exists 'truncate))
     (hasheq 'ok #t 'cancelled #f
             'bytes (if (bytes? payload) (bytes-length payload) (string-length payload))
             'phrase (s l 'phrase-saved)
             'summary (workspace-summary l))))]

  [(POST "api/learn/checksum" #:returns GValue)
   (learn-checksum [line GString] [lang GString "en"])
   (guard (norm-lang lang) (lambda ()
     (learn-checksum-response (norm-lang lang) line)))]

  [(POST "api/learn/srec-steps" #:returns GValue)
   (learn-srec-steps [lang GString "en"])
   (guard (norm-lang lang) (lambda ()
     ;; Static teaching vector: count 05, address 0, stored FA — the
     ;; one's-complement arithmetic shown step by step.
     (define payload '(5 0 0 0 0))
     (define sum (foldl + 0 payload))
     (define low (remainder sum 256))
     (define expected (remainder (- 255 low) 256))
     (hasheq 'ok #t 'sum sum 'low low 'expected expected 'stored 250 'pass (= 250 expected)
             'steps (list (hasheq 'label (s (norm-lang lang) 'learn-intel-step-1)
                                  'value "05 + 00 + 00 + 00 + 00 = 0x05"
                                  'note (s (norm-lang lang) 'learn-intel-step-1-note))
                          (hasheq 'label (s (norm-lang lang) 'learn-intel-step-2)
                                  'value (string-append "0x05 & FF = " (hex-str low 2))
                                  'note (s (norm-lang lang) 'learn-intel-step-2-note))
                          (hasheq 'label (s (norm-lang lang) 'learn-srec-step-3)
                                  'value (string-append "FF - " (hex-str low 2) " = " (hex-str expected 2))
                                  'note (s (norm-lang lang) 'learn-srec-step-3-note))
                          (hasheq 'label (s (norm-lang lang) 'learn-intel-step-4)
                                  'value (string-append "FA = " (hex-str expected 2))
                                  'note (s (norm-lang lang) 'learn-intel-step-4-note))))))]

  [(POST "api/app/update-check" #:returns GValue)
   (app-update-check [lang GString "en"])
   (guard (norm-lang lang) (lambda ()
     (define l (norm-lang lang))
     ;; Family notify-and-open semantics: a failed check degrades to
     ;; "up to date", never to a less-verified claim.
     (define candidate (check-update-signed app-version))
     (if candidate
         (hasheq 'ok #t 'update-available #t
                 'version (hash-ref candidate 'version)
                 'url (hash-ref candidate 'url)
                 'phrase (format (s l 'update-available) (hash-ref candidate 'version)))
         (hasheq 'ok #t 'update-available #f
                 'phrase (s l 'update-uptodate)))))]

  [(POST "api/workspace/load-source" #:returns GValue)
   (workspace-load-source [source GString] [name GString "pasted.txt"] [lang GString "en"])
   (guard (norm-lang lang) (lambda ()
     (define l (norm-lang lang))
     (update! (lambda (_)
                (make-workspace-from-bytes name (string->bytes/utf-8 source))))
     (hasheq 'ok #t 'phrase (s l 'phrase-loaded)
             'summary (workspace-summary l))))])

(module+ test
  (require rackunit)
  ;; Health and the workspace contract, no display needed.
  (check-equal? (hash-ref (health) 'ok) #t)
  (update! (lambda (_) (sample-workspace)))
  (define summary (workspace-summary "en"))
  (check-equal? (hash-ref summary 'kind) "intel")
  (check-equal? (hash-ref (hash-ref summary 'stats) 'data-bytes) 64)
  (check-equal? (hash-ref summary 'revision) 0)
  ;; Preview the fill operation without committing.
  (define preview
    (guard "en"
           (lambda ()
             (preview-response "en" 'fill
                               (hasheq 'start "0x08000020" 'end "0x08007FFF" 'value "0xFF")))))
  (check-true (hash-ref preview 'ok))
  (check-equal? (hash-ref preview 'added) 32736)
  (check-equal? (workspace-revision (current)) 0) ; preview never commits
  ;; Apply bumps the revision and removes the FBL/APP gap.
  (define applied
    (guard "en"
           (lambda ()
             (ops-apply "fill"
                        (hasheq 'start "0x08000020" 'end "0x08007FFF" 'value "0xFF")
                        0 "en"))))
  (check-true (hash-ref applied 'ok))
  (check-equal? (workspace-revision (current)) 1)
  ;; The FBL/APP gap is gone; the APP-area internal holes remain.
  (check-equal? (hash-ref (car (image-gaps (workspace-image (current)))) 'start)
                134250504)
  ;; CRC over the sample APP range (holes substituted with 0xFF).
  (define crc-response
    (guard "en"
           (lambda ()
             (preview-response "en" 'crc
                               (hasheq 'preset "CRC-32/MPEG-2"
                                       'start "0x08008000" 'end "0x08009FFF" 'value "0xFF")))))
  (check-true (hash-ref crc-response 'ok))
  (check-equal? (hash-ref (hash-ref crc-response 'crc) 'gaps) 8160)
  ;; Error localization through the guard.
  (define blocked
    (guard "zh"
           (lambda ()
             (preview-response "zh" 'fill
                               (hasheq 'start "0x200" 'end "0x100" 'value "0xFF")))))
  (check-false (hash-ref blocked 'ok))
  (check-equal? (hash-ref blocked 'error-key) 'err-start-above-end)
  (check-equal? (hash-ref blocked 'error) "起始地址必须不大于结束地址。")
  ;; Learn checksum teaching arithmetic: the corrupted sample line fails.
  (define learn
    (guard "en" (lambda () (learn-checksum-response "en" ":0480200048B1084700"))))
  (check-true (hash-ref learn 'valid))
  (check-false (hash-ref learn 'pass))
  (check-equal? (hash-ref learn 'expected) 20)
  ;; Reset restores revision 0.
  (reset-workspace)
  (check-equal? (workspace-revision (current)) 0)
  ;; Patch through the typed API: preview reports, apply commits.
  (define patch-preview
    (guard "en"
           (lambda ()
             (ops-preview "patch" (hasheq 'address "0x08008010" 'bytes "00 BF") "en"))))
  (check-true (hash-ref patch-preview 'ok))
  (check-equal? (hash-ref patch-preview 'changed) 2)
  (check-equal? (hash-ref patch-preview 'added) 0)
  (check-equal? (hash-ref patch-preview 'note) (hash-ref en-strings 'note-patch))
  (check-equal? (workspace-revision (current)) 0) ; preview never commits
  (define patch-applied
    (guard "en"
           (lambda ()
             (ops-apply "patch" (hasheq 'address "0x08008010" 'bytes "00BF") 0 "en"))))
  (check-true (hash-ref patch-applied 'ok))
  (check-equal? (workspace-revision (current)) 1)
  (check-equal? (image-ref (workspace-image (current)) 134250512) 0)
  (check-equal? (image-ref (workspace-image (current)) 134250513) 191)
  (check-equal? (length (workspace-records (current))) 8) ; source records stay verbatim
  ;; Bytes landing in a hole are reported as new data, localized.
  (define patch-gap
    (guard "zh"
           (lambda ()
               (ops-preview "patch" (hasheq 'address "0x08008020" 'bytes "48 B1 08 47") "zh"))))
  (check-equal? (hash-ref patch-gap 'added) 4)
  (check-equal? (hash-ref patch-gap 'note) (hash-ref zh-strings 'note-patch-gap))
  ;; No-change patch, malformed payload, and the CRC reject-gap message.
  (define patch-same
    (guard "en"
           (lambda ()
             (ops-preview "patch" (hasheq 'address "0x08008010" 'bytes "00 BF") "en"))))
  (check-equal? (hash-ref patch-same 'error-key) 'err-patch-nochange)
  (check-equal? (hash-ref patch-same 'error) (hash-ref en-strings 'err-patch-nochange))
  (define patch-bad
    (guard "en"
           (lambda ()
             (ops-preview "patch" (hasheq 'address "0x08008010" 'bytes "GG") "en"))))
  (check-equal? (hash-ref patch-bad 'error-key) 'err-bytes-format)
  (define crc-reject
    (guard "en"
           (lambda ()
             (ops-preview "crc"
                          (hasheq 'preset "CRC-32/MPEG-2"
                                  'start "0x08008000" 'end "0x08009FFF" 'value "reject")
                          "en"))))
  (check-equal? (hash-ref crc-reject 'error-key) 'err-crc-unmapped-at)
  (check-true (string-prefix? (hash-ref crc-reject 'error)
                              (hash-ref en-strings 'err-crc-unmapped-at)))
  ;; Specs: patch is the second card, with a bytes field and its own help.
  (define specs (hash-ref (ops-specs "en") 'ops))
  (check-equal? (map (lambda (o) (hash-ref o 'id)) specs)
                '("fill" "patch" "pad" "offset" "crop" "merge" "convert" "crc"))
  (define patch-spec (list-ref specs 1))
  (check-equal? (map (lambda (f) (hash-ref f 'kind)) (hash-ref patch-spec 'fields))
                '("address" "bytes"))
  (check-equal? (hash-ref patch-spec 'help) (hash-ref en-strings 'field-help-patch))
  (check-false (hash-ref (car specs) 'help))
  ;; Key parity: en and zh carry the same keys (中英同源), so no message
  ;; can fall back to its raw key in one language.
  (check-equal? (sort (hash-keys en-strings) symbol<?)
                (sort (hash-keys zh-strings) symbol<?))
  (reset-workspace))
