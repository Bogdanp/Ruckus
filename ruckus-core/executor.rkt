#lang racket/base

(require noise/backend
         noise/serde
         racket/pretty
         syntax/modread
         "resolver.rkt"
         "streaming-actor.rkt")

(provide
 (record-out ExecutionOutput)
 (enum-out ExecutionStep))

(define-record ExecutionOutput
  [stdout : Bytes]
  [stderr : Bytes])

(define-enum ExecutionStep
  [done {output : ExecutionOutput}]
  [more {output : ExecutionOutput}])

(define (evaluate in)
  (define-values (document-dir document-name _is-dir?)
    (split-path (format "~a" (object-name in))))
  (define document-id
    (string->symbol (path->string document-name)))
  (define document-spec `',document-id)
  (parameterize ([current-module-declare-name (make-resolved-module-path document-id)]
                 [current-module-name-resolver (make-collects-resolver)]
                 [current-namespace (make-base-empty-namespace)]
                 [current-directory document-dir])
    (namespace-require 'ruckus/openssl)
    (eval
     (check-module-form
      (with-module-reading-parameterization
        (lambda ()
          (read-syntax #f in)))
      #;expected-module-sym 'ignored
      #;source-v #f))
    (let/ec exit
      (parameterize ([current-print pretty-print*]
                     [exit-handler exit])
        (namespace-require document-spec)))
    (namespace-mapped-symbols (module->namespace document-spec))))

(define (pretty-print* v)
  (unless (void? v)
    (parameterize ([pretty-print-columns 80])
      (pretty-print v))))

(define callout-installed? #f)
(define-callout (on-executor-step [execution-id : UVarint]))
(define-rpc (mark-on-executor-step-installed)
  (set! callout-installed? #t))

(define (notify-step id)
  (when callout-installed?
    (on-executor-step id)))

(define the-executor
  (streaming-actor notify-step))

(define (execute-worker path)
  (define symbols-box (box null))
  (define worker
    (thread
     (lambda ()
       (define syms (call-with-input-file path evaluate))
       (set-box! symbols-box syms))))
  (values worker symbols-box))

(define-rpc (execute-script [at-path path : String] : UVarint)
  (streaming-start the-executor (lambda () (execute-worker path))))

(define-rpc (step-execution [_ id : UVarint] : ExecutionStep)
  (define out (streaming-step the-executor id))
  (define the-output (ExecutionOutput (streaming-output-stdout out)
                                      (streaming-output-stderr out)))
  (if (streaming-output-done? out)
      (ExecutionStep.done the-output)
      (ExecutionStep.more the-output)))

(define-rpc (stop-execution [_ id : UVarint])
  (streaming-stop the-executor id))

(define-rpc (get-execution-symbols [_ id : UVarint] : (Listof String))
  (map symbol->string (unbox (streaming-peek the-executor id))))

(define-rpc (get-racket-base-symbols : (Listof String))
  (map symbol->string (namespace-mapped-symbols (module->namespace 'racket/base))))
