#lang racket/base

;; Sniffing and ELF summary tests with synthetic content only.

(require rackunit
         racket/list
         "detect.rkt"
         "image.rkt") ; exn:fail:bitsmith

;; ---- little-endian integer builders for the synthetic ELF ------------------

(define (u16le n) (list (bitwise-and n 255) (bitwise-and (arithmetic-shift n -8) 255)))
(define (u32le n) (append (u16le n) (u16le (arithmetic-shift n -16))))
(define (u64le n) (append (u32le n) (u32le (arithmetic-shift n -32))))

;; ---- sniffing ---------------------------------------------------------------

(define intel-head
  (string->bytes/utf-8
   (string-append ":020000040800F2\n:200000000010020009590108FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7B\n")))
(define srec-head
  (string->bytes/utf-8
   (string-append "S0120000496D61676542656E63682D44454D4FD8\r\nS31D004000000050002001598A08FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF56\n")))
(define bin-head (bytes #x00 #x20 #x00 #x10 #x09 #x59))

;; Extensionless ELF (content decides).
(define elf-head (bytes #x7f #x45 #x4c #x46 2 1 1 0 0 0 0 0 0 0 0 0))

(check-equal? (hash-ref (sniff-bytes intel-head) 'kind) 'intel)
(check-equal? (hash-ref (sniff-bytes srec-head) 'kind) 'srec)
(check-equal? (hash-ref (sniff-bytes bin-head) 'kind) 'bin)
(check-equal? (hash-ref (sniff-bytes elf-head) 'kind) 'elf)

;; BOM-tolerant (Windows editors emit these).
(check-equal?
 (hash-ref (sniff-bytes (bytes-append (bytes #xEF #xBB #xBF) intel-head)) 'kind) 'intel)

;; Leading whitespace tolerated.
(check-equal? (hash-ref (sniff-bytes (string->bytes/utf-8 "\n\n S1050000F8")) 'kind) 'srec)

;; ---- synthetic ELF64 little-endian -----------------------------------------

;; Section-name string table: \0 ".text\0" ".data\0"
(define shstrtab
  (apply bytes (append (list 0 46 116 101 120 116 0 46 100 97 116 97 0))))

;; ELF64 section header: name u32, type u32, flags u64, addr u64,
;; offset u64, size u64, link u32, info u32, addralign u64, entsize u64.
(define (section name-off type addr offset size)
  (append (u32le name-off) (u32le type) (u64le 0) (u64le addr)
          (u64le offset) (u64le size)
          (list 0 0 0 0) (list 0 0 0 0)     ; link, info (u32 zeros)
          (u64le 4) (u64le 16)))

(define section-offset 64)                 ; header table: 64..320 (4x64)
(define text-offset 512)
(define data-offset 544)
(define strtab-offset 560)
(define headers
  (append (section 1 1 #x08000000 text-offset 32)      ; .text PROGBITS
          (section 7 1 #x08008000 data-offset 16)      ; .data PROGBITS
          (section 0 0 0 0 0)                          ; null section
          (section 1 3 0 strtab-offset 13)))           ; .shstrtab STRTAB

(define text-bytes (make-bytes 32 #xAA))
(define data-bytes (make-bytes 16 #xBB))
(define header-padding (make-bytes (- text-offset section-offset (* 4 64)) 0))

(define elf
  (bytes-append
   (apply bytes (append (list 127 69 76 70 2 1 1 0) (make-list 8 0))) ; ident: 64-bit LE
   (apply bytes (u16le 2))                    ; EXEC
   (apply bytes (u16le 40))                   ; EM_ARM
   (apply bytes (u32le 1))                    ; version
   (apply bytes (u64le #x08000000))           ; entry
   (apply bytes (u64le 0))                    ; phoff
   (apply bytes (u64le section-offset))       ; shoff
   (apply bytes (u32le 0))                    ; flags
   (apply bytes (u16le 64))                   ; ehsize
   (apply bytes (u16le 0))                    ; phentsize
   (apply bytes (u16le 0))                    ; phnum
   (apply bytes (u16le 64))                   ; shentsize
   (apply bytes (u16le 4))                    ; shnum
   (apply bytes (u16le 3))                    ; shstrndx -> strtab section index 3
   (apply bytes headers)
   header-padding
   text-bytes
   data-bytes
   shstrtab))

 ; 573

(define summary (elf-summary elf))
(check-equal? (hash-ref summary 'type) "EXEC (executable)")
(check-equal? (hash-ref summary 'entry) #x08000000)
(check-false (hash-ref summary 'big-endian?))
(define sections (hash-ref summary 'sections))
(check-equal? (length sections) 4)
(check-equal? (hash-ref (list-ref sections 0) 'name) ".text")
(check-equal? (hash-ref (list-ref sections 0) 'address) #x08000000)
(check-equal? (hash-ref (list-ref sections 0) 'size) 32)
(check-equal? (hash-ref (list-ref sections 0) 'loadable) #t)
(check-equal? (hash-ref (list-ref sections 1) 'name) ".data")
(check-equal? (hash-ref (list-ref sections 1) 'size) 16)
(check-equal? (hash-ref (list-ref sections 2) 'loadable) #f) ; null section

;; ---- rejection paths ---------------------------------------------------------

(check-exn exn:fail:bitsmith? (lambda () (elf-summary (bytes #x7f #x45 #x4c #x46 3 1 1 0))))
(check-exn exn:fail:bitsmith? (lambda () (elf-summary (bytes 1 2 3))))
(check-exn exn:fail:bitsmith? (lambda () (elf-summary (make-bytes 10 0))))
