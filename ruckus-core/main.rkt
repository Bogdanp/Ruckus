#lang racket/base

(require noise/backend
         noise/serde
         openssl
         racket/runtime-path

         ;; For effect:
         "executor.rkt"
         "filesystem.rkt")

(provide
 main)

(define-runtime-path cacert.cer
  "cacert.cer")

(ssl-default-verify-sources
 (list cacert.cer))

(define-rpc (ping : String)
  "pong")

(define (main in-fd out-fd)
  (module-cache-clear!)
  (collect-garbage)
  (let/cc trap
    (parameterize ([exit-handler
                    (lambda (err-or-code)
                      (when (exn:fail? err-or-code)
                        ((error-display-handler)
                         (format "trap: ~a" (exn-message err-or-code))
                         err-or-code))
                      (trap))])
      (define stop (serve in-fd out-fd))
      (with-handlers ([exn:break? void])
        (sync/enable-break never-evt))
      (stop))))
