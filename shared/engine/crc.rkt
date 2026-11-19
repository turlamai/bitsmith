#lang racket/base

;; CRC / additive checksum presets over a byte list.
;;
;; Presets (parameters surface in the UI; never invented):
;;   CRC-32/MPEG-2  — automotive project preset: poly 0x04C11DB7,
;;                    init 0xFFFFFFFF, xorout 0xFFFFFFFF, no reflection.
;;                    Note: conventional MPEG-2 uses xorout 0x00000000;
;;                    the project brief pins 0xFFFFFFFF and the UI labels it.
;;   CRC-32/ISO-HDLC — zlib-compatible, reflected in/out.
;;   CRC-16/XMODEM  — poly 0x1021, init 0, xorout 0, no reflection.
;;   sum8           — additive, bytes modulo 256.
;;
;; Reference vectors: ASCII "123456789" -> 0x0376E6E7 / 0xCBF43926 /
;; 0x31C3 / 0xDD.

(provide crc-presets
         crc-compute
         crc-preset-names)

;; bit loops keep the implementation transparent to audit; ranges are
;; bounded to 1 MiB by the operations layer, so speed is not critical.
(define (crc32-noreflect bytes init poly xorout)
  (let loop ([c init] [bs bytes])
    (if (null? bs)
        (bitwise-and (bitwise-xor c xorout) 4294967295)
        (let inner ([c (bitwise-xor c (arithmetic-shift (car bs) 24))] [k 0])
          (if (= k 8)
              (loop c (cdr bs))
              (inner (bitwise-and
                      (bitwise-xor (arithmetic-shift c 1)
                                   (if (bitwise-bit-set? c 31) poly 0))
                      4294967295)
                     (add1 k)))))))

(define (crc32-reflect bytes init xorout)
  (let loop ([c init] [bs bytes])
    (if (null? bs)
        (bitwise-and (bitwise-xor c xorout) 4294967295)
        (let inner ([c (bitwise-xor c (car bs))] [k 0])
          (if (= k 8)
              (loop c (cdr bs))
              (inner (bitwise-xor (arithmetic-shift c -1)
                                  (if (even? c) 0 3988292384)) ; 0xEDB88320
                     (add1 k)))))))

(define (crc16-noreflect bytes init poly xorout)
  (let loop ([c init] [bs bytes])
    (if (null? bs)
        (bitwise-and (bitwise-xor c xorout) 65535)
        (let inner ([c (bitwise-xor c (arithmetic-shift (car bs) 8))] [k 0])
          (if (= k 8)
              (loop c (cdr bs))
              (inner (bitwise-and
                      (bitwise-xor (arithmetic-shift c 1)
                                   (if (bitwise-bit-set? c 15) poly 0))
                      65535)
                     (add1 k)))))))

;; Preset table: id -> (hash params + note key). Notes are i18n keys, the
;; strings module supplies the copy so presets stay language-agnostic here.
(define crc-presets
  (hasheq
   'mpeg2 (hasheq 'id 'mpeg2 'label "CRC-32/MPEG-2" 'bits 32
                  'poly 79764919 ; 0x04C11DB7
                  'init 4294967295
                  'xor 4294967295
                  'reflect #f
                  'note-key 'crc-note-mpeg2)
   'iso-hdlc (hasheq 'id 'iso-hdlc 'label "CRC-32/ISO-HDLC" 'bits 32
                     'poly 79764919
                     'init 4294967295
                     'xor 4294967295
                     'reflect #t
                     'note-key 'crc-note-iso-hdlc)
   'xmodem (hasheq 'id 'xmodem 'label "CRC-16/XMODEM" 'bits 16
                   'poly 4129 ; 0x1021
                   'init 0
                   'xor 0
                   'reflect #f
                   'note-key 'crc-note-xmodem)
   'sum8 (hasheq 'id 'sum8 'label "sum8" 'bits 8
                 'poly 0 'init 0 'xor 0 'reflect #f
                 'note-key 'crc-note-sum8)))

(define crc-preset-names
  (for/list ([(id preset) (in-hash crc-presets)])
    (hash-ref preset 'label)))

(define (crc-compute bytes preset)
  ;; Accept bytes or a byte list; the bit loops walk lists.
  (define data (if (bytes? bytes) (bytes->list bytes) bytes))
  (case (hash-ref preset 'id)
    [(sum8) (remainder (foldl + 0 data) 256)]
    [else
     (case (hash-ref preset 'bits)
       [(16) (crc16-noreflect data (hash-ref preset 'init)
                              (hash-ref preset 'poly) (hash-ref preset 'xor))]
       [else (if (hash-ref preset 'reflect)
                 (crc32-reflect data (hash-ref preset 'init) (hash-ref preset 'xor))
                 (crc32-noreflect data (hash-ref preset 'init)
                                  (hash-ref preset 'poly) (hash-ref preset 'xor)))])]))

(module+ test
  (require rackunit)
  (define vector (map char->integer (string->list "123456789")))
  ;; Project preset pins xorout 0xFFFFFFFF (labelled in the UI); this
  ;; matches the catalog's CRC-32/BZIP2 arithmetic for the standard vector.
  (check-equal? (crc-compute vector (hash-ref crc-presets 'mpeg2)) 4236843288) ; 0xFC891918
  ;; Conventional MPEG-2 (xorout 0) cross-checks the non-reflected loop.
  (check-equal?
   (crc-compute vector (hash-set (hash-ref crc-presets 'mpeg2) 'xor 0))
   58124007) ; 0x0376E6E7
  (check-equal? (crc-compute vector (hash-ref crc-presets 'iso-hdlc)) 3421780262) ; 0xCBF43926
  (check-equal? (crc-compute vector (hash-ref crc-presets 'xmodem)) 12739)     ; 0x31C3
  (check-equal? (crc-compute vector (hash-ref crc-presets 'sum8)) 221)         ; 0xDD
  ;; Empty input: initialized CRCs expose init ^ xorout.
  (check-equal? (crc-compute '() (hash-ref crc-presets 'mpeg2)) 0)
  (check-equal? (crc-compute '() (hash-ref crc-presets 'iso-hdlc)) 0)
  (check-equal? (crc-compute '() (hash-ref crc-presets 'xmodem)) 0)
  (check-equal? (crc-compute '() (hash-ref crc-presets 'sum8)) 0))
