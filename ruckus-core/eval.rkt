#lang racket/base

(require noise/backend
         noise/serde
         racket/file
         racket/sandbox)

(provide
 (record-out EvaluateResult))

(define-record EvaluateResult
  [stdout : Bytes]
  [stderr : Bytes])

(define-rpc (evaluate [code : String] : EvaluateResult)
  (call-with-trusted-sandbox-configuration
   (lambda ()
     (call-with-temporary-file
      (lambda (path)
        (call-with-output-file path
          #:exists 'replace
          (lambda (out)
            (write-string code out)))
        (define stdout (open-output-bytes))
        (define stderr (open-output-bytes))
        (parameterize ([sandbox-output stdout]
                       [sandbox-error-output stderr]
                       [sandbox-path-permissions '((read #rx#".*"))])
          (define ev (make-evaluator 'racket/base))
          (ev
           `(with-handlers ([exn?
                             (lambda (e)
                               ((error-display-handler)
                                (format "evaluate: ~a"
                                        (exn-message e))
                                e))])
              (dynamic-require '(file ,(path->string path)) #f)))
          (EvaluateResult
           (get-output-bytes stdout)
           (get-output-bytes stderr))))))))

(define (call-with-temporary-file proc)
  (define path #f)
  (dynamic-wind
    (lambda ()
      (set! path (make-temporary-file)))
    (lambda ()
      (proc path))
    (lambda ()
      (delete-file path))))
