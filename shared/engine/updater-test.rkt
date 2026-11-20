#lang racket/base

;; Updater trust-chain tests with self-generated fixture keys: a signed
;; wrapper verifies, a tampered payload and a wrong key both fail, and the
;; embedded release key stays loadable. No network.

(require rackunit
         json
         racket/string
         crypto
         (only-in crypto/libcrypto libcrypto-factory)
         glaze/update
         net/base64
         "updater.rkt")

;; Fixture keypair through libcrypto only — its PKCS#8 datum is the same
;; encoding the OpenSSL-generated release key uses (rivet update-keys pattern).

(crypto-factories (list libcrypto-factory))

(define (b64 value) (string-trim (bytes->string/utf-8 (base64-encode value ""))))
(define (b64->bytes value) (base64-decode (string->bytes/utf-8 value)))

;; Fixture keypair distinct from the embedded release key.
(define fixture-private
  (generate-private-key (get-pk 'eddsa libcrypto-factory) '((curve ed25519))))
;; rkt-public datum roundtrip — the exact pattern make-update-manifest.sh
;; uses to check the signing key against the embedded public key.
(define fixture-public
  (datum->pk-key (pk-key->datum fixture-private 'rkt-public) 'rkt-public))
(define fixture-public-der (pk-key->datum fixture-public 'SubjectPublicKeyInfo))

(define (sign-wrapper private-key payload key-id)
  (define signature (pk-sign private-key payload))
  (hasheq 'schema 1
          'payload (b64 payload)
          'signature
          (hasheq 'algorithm "ed25519" 'key_id key-id 'value (b64 signature))))

(define sample-manifest
  (update-manifest "io.glaze.Bitsmith"
                   "0.2.0"
                   1
                   'stable
                   "2026-11-20T00:00:00Z"
                   "0.0.0"
                   #f
                   #t
                   100
                   (list (update-artifact 'macos 'arm64
                                          "https://example.invalid/bitsmith-0.2.0-macos-arm64.zip"
                                          "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
                                          2
                                          'zip
                                          '()
                                          #f))))

(define payload (update-manifest->payload-bytes sample-manifest))

;; ---- embedded release key loads --------------------------------------------

(check-equal? (pk-key->datum (embedded-public-key) 'SubjectPublicKeyInfo)
              (b64->bytes update-public-key-b64))
(check-equal? app-identifier "io.glaze.Bitsmith")
(check-equal? update-key-id "bitsmith-2026-11")

;; ---- positive: fixture-signed wrapper verifies against the fixture key -----

(define good (sign-wrapper fixture-private payload "bitsmith-2026-11"))
(define verified
  (verify-manifest-signature (open-input-bytes (string->bytes/utf-8 (jsexpr->string good)))
                             #:key-id "bitsmith-2026-11"
                             #:public-key fixture-public))
(check-equal? (update-manifest-version verified) "0.2.0")

;; Exact-message primitive agrees.
(check-true (ed25519-verify-message payload
                                    (hash-ref (hash-ref good 'signature) 'value)
                                    #:public-key fixture-public))

;; ---- tamper: one flipped payload byte breaks the signature ------------------

(define tampered-bytes (bytes-copy payload))
(bytes-set! tampered-bytes 0 (bitwise-xor (bytes-ref tampered-bytes 0) 1))
(define tampered
  (hash-set good 'payload (b64 tampered-bytes)))
(check-exn exn:fail?
           (lambda ()
             (verify-manifest-signature
              (open-input-bytes (string->bytes/utf-8 (jsexpr->string tampered)))
              #:key-id "bitsmith-2026-11"
              #:public-key fixture-public)))

;; ---- wrong key id: a signature from another family key is rejected ----------

(define wrong-id (sign-wrapper fixture-private payload "bitsmith-2025-01"))
(check-exn exn:fail:contract?
           (lambda ()
             (verify-manifest-signature
              (open-input-bytes (string->bytes/utf-8 (jsexpr->string wrong-id)))
              #:key-id "bitsmith-2026-11"
              #:public-key fixture-public)))

;; ---- garbage signature b64 degrades to a verify failure, not an error -------

(check-false (ed25519-verify-message payload "not-base64!!"
                                     #:public-key fixture-public))

;; ---- malformed wrapper (truncated) raises rather than passing ---------------

(check-exn exn:fail?
           (lambda ()
             (verify-manifest-signature (open-input-bytes #"{\"schema\": 1, ")
                                        #:key-id #f
                                        #:public-key fixture-public)))

;; ---- manifest-url: https enforcement lives in check-update-signed ----------

;; With an http:// override the check degrades to #f (never a downgrade).
(putenv "BITSMITH_UPDATE_MANIFEST" "http://127.0.0.1:1/no-such-feed")
(check-false (check-update-signed "0.1.0"))
;; Unreachable https feed also degrades to #f.
(putenv "BITSMITH_UPDATE_MANIFEST" "https://127.0.0.1:1/no-such-feed")
(check-false (check-update-signed "0.1.0"))
(putenv "BITSMITH_UPDATE_MANIFEST" "")
