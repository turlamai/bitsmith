#lang racket/base

;; Content sniffing and read-only format summaries.
;;
;; Extensions lie: extensionless ELF files are real. The sniffer decides
;; from content only — the extension is a hint the UI surfaces, never a
;; decision input.
;;
;;   ":" at the start                -> intel
;;   /^S[0-9A-F]/ within the head    -> srec
;;   ELF magic                       -> elf (read-only summary)
;;   anything else                   -> bin (base becomes an assumption)

(require racket/match
         racket/string
         "image.rkt")

(provide sniff-bytes
         sniff-label
         elf-summary)

(define (sniff-label kind)
  (case kind
    [(intel) "Intel HEX"]
    [(srec) "Motorola S-record"]
    [(elf) "ELF"]
    [(bin) "Raw BIN"]
    [else "Unknown"]))

;; sniff-bytes : bytes -> (hash kind label) — content only, extension is a
;; UI hint, never a decision input.
(define (sniff-bytes head)
  (define text (text-of head))
  (define trimmed (and text (string-trim text)))
  (cond
    [(elf-magic? head) (hasheq 'kind 'elf 'label (sniff-label 'elf))]
    [(and trimmed (string-prefix? trimmed ":"))
     (hasheq 'kind 'intel 'label (sniff-label 'intel))]
    [(and trimmed (regexp-match? #rx"^S[0-9A-Fa-f]" trimmed))
     (hasheq 'kind 'srec 'label (sniff-label 'srec))]
    [else (hasheq 'kind 'bin 'label (sniff-label 'bin))]))

;; BOM-tolerant lossy decode of the head for text formats.
(define (text-of head)
  (with-handlers ([exn:fail? (lambda (_) #f)])
    (let* ([clean (if (and (>= (bytes-length head) 3)
                           (= (bytes-ref head 0) 239)
                           (= (bytes-ref head 1) 187)
                           (= (bytes-ref head 2) 191))
                      (subbytes head 3)
                      head)])
      (bytes->string/utf-8 clean #\uFFFD))))

(define (elf-magic? head)
  (and (>= (bytes-length head) 4)
       (= (bytes-ref head 0) 127)
       (= (bytes-ref head 1) 69) ; E
       (= (bytes-ref head 2) 76) ; L
       (= (bytes-ref head 3) 70))) ; F

;; ---- ELF read-only summary --------------------------------------------------
;;
;; Covers ELF32/ELF64, little- and big-endian. Anything else reports
;; unsupported rather than guessing. Sections, entry point and type — the
;; summary a firmware developer needs before deciding what to open next.

(define (elf-summary data)
  (unless (elf-magic? data)
    (raise-bitsmith-error 'err-not-elf))
  (when (< (bytes-length data) 64)
    (raise-bitsmith-error 'err-elf-truncated))
  (define ei-class (bytes-ref data 4))
  (define ei-data (bytes-ref data 5))
  (unless (or (= ei-class 1) (= ei-class 2))
    (raise-bitsmith-error 'err-elf-unsupported-class))
  (unless (or (= ei-data 1) (= ei-data 2))
    (raise-bitsmith-error 'err-elf-unsupported-data))
  (define bit32? (= ei-class 1))
  (define big? (= ei-data 2))
  (define (u16 off) (read-uint data off 2 big?))
  (define (u32 off) (read-uint data off 4 big?))
  (define (u64 off) (read-uint data off 8 big?))
  (define e-type (u16 16))
  (define e-machine (u16 18))
  (define entry (if bit32? (u32 24) (u64 24)))
  (define shoff (if bit32? (u32 32) (u64 40)))
  ;; e_shentsize / e_shnum / e_shstrndx are u16 fields in both classes.
  (define shentsize (u16 (if bit32? 46 58)))
  (define shnum (u16 (if bit32? 48 60)))
  (define shstrndx (u16 (if bit32? 50 62)))
  (when (or (= shnum 0) (= shentsize 0))
    (raise-bitsmith-error 'err-elf-no-sections))
  (define (sh-field index offset size)
    (read-uint data (+ shoff (* index shentsize) offset) size big?))
  ;; Section offsets: ELF32 sh_offset @16 (u32); ELF64 sh_offset @24 (u64).
  (define shstrtab-off
    (if bit32? (sh-field shstrndx 16 4) (sh-field shstrndx 24 8)))
  (define shstrtab-size (sh-field shstrndx (if bit32? 20 32) 4))
  (define strtab
    (subbytes data shstrtab-off (min (bytes-length data) (+ shstrtab-off shstrtab-size))))
  (define sections
    (for/list ([i (in-range (min shnum 256))])
      (define name-off (sh-field i 0 4))
      (define s-type (sh-field i 4 4))
      (define s-addr (if bit32? (sh-field i 12 4) (sh-field i 16 8)))
      (define s-off (if bit32? (sh-field i 16 4) (sh-field i 24 8)))
      (define s-size (if bit32? (sh-field i 20 4) (sh-field i 32 8)))
      (hasheq 'name (c-string strtab name-off)
              'type s-type
              'address s-addr
              'offset s-off
              'size s-size
              'loadable (and (> s-size 0)
                             (not (= s-type 8)) ; SHT_NOBITS
                             (not (= s-type 0))))))
  (hasheq 'bit32? bit32?
          'big-endian? big?
          'type (elf-type-name e-type)
          'machine e-machine
          'entry entry
          'sections sections))

(define (elf-type-name t)
  (case t
    [(1) "REL (relocatable)"]
    [(2) "EXEC (executable)"]
    [(3) "DYN (shared)"]
    [(4) "CORE"]
    [else (string-append "type " (number->string t))]))

(define (c-string strtab off)
  (define end
    (or (for/first ([i (in-range off (bytes-length strtab))] #:when (= (bytes-ref strtab i) 0)) i)
        (bytes-length strtab)))
  (if (>= off (bytes-length strtab))
      ""
      (bytes->string/utf-8 (subbytes strtab off end))))

(define (read-uint data off size big?)
  (unless (<= (+ off size) (bytes-length data))
    (raise-bitsmith-error 'err-elf-truncated))
  (for/fold ([acc 0])
            ([i (in-range size)])
    (define b (bytes-ref data (+ off (if big? i (- size 1 i)))))
    (+ (* acc 256) b)))
