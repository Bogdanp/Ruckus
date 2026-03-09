#lang racket/base

(require actor
         noise/backend
         noise/serde
         struct-define
         syntax/modread
         "resolver.rkt")

(provide
 (record-out ExecutionOutput)
 (enum-out ExecutionStep))

(define-record ExecutionOutput
  [stdout : Bytes]
  [stderr : Bytes])

(define-enum ExecutionStep
  [done {output : ExecutionOutput}]
  [more {output : ExecutionOutput}])

(struct state (sequence executions))
(struct execution (id path custodian evaluation symbols-box stdout stderr pending-stdout pending-stderr))

(define (make-state)
  (state
   #;sequence 0
   #;executions (hasheqv)))

(define (make-execution id path)
  (define symbols-box (box null))
  (define custodian (make-custodian))
  (parameterize ([current-custodian custodian])
    (define-values (stdout-in stdout-out) (make-pipe))
    (define-values (stderr-in stderr-out) (make-pipe))
    (define evaluation
      (parameterize ([current-output-port stdout-out]
                     [current-error-port stderr-out])
        (thread
         (lambda ()
           (define syms (call-with-input-file path evaluate))
           (set-box! symbols-box syms)))))
    (execution
     #;id id
     #;path path
     #;custodian custodian
     #;evaluation evaluation
     #;symbols-box symbols-box
     #;stdout stdout-in
     #;stderr stderr-in
     #;pending-stdout (open-output-bytes)
     #;pending-stderr (open-output-bytes))))

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
    (eval
     (check-module-form
      (with-module-reading-parameterization
        (lambda ()
          (read-syntax #f in)))
      #;expected-module-sym 'ignored
      #;source-v #f))
    (namespace-require document-spec)
    (namespace-mapped-symbols (module->namespace document-spec))))

(define-actor (executor)
  #:state (make-state)
  #:event (lambda (st)
            (apply
             choice-evt
             (for/list ([ex (in-hash-values (state-executions st))])
               (struct-define execution ex)
               (choice-evt
                (handle-evt
                 (if evaluation (thread-dead-evt evaluation) never-evt)
                 (lambda (_)
                   (struct-define state st)
                   (define updated-execution
                     (struct-copy
                      execution ex
                      [evaluation #f]))
                   (when callout-installed?
                     (on-executor-step id))
                   (struct-copy
                    state st
                    [executions (hash-set executions id updated-execution)])))
                (handle-evt
                 (choice-evt stdout stderr)
                 (lambda (src)
                   (define dst
                     (if (eq? src stdout)
                         pending-stdout
                         pending-stderr))
                   (copy-bytes-avail src dst)
                   (when callout-installed?
                     (on-executor-step id))
                   st))))))

  (define/private (get-execution st id)
    (hash-ref
     #;ht (state-executions st)
     #;key id
     #;failure-result
     (lambda ()
       (error 'get-execution "execution ~s not found" id))))

  (define (symbols st id)
    (struct-define state st)
    (let ([ex (get-execution st id)])
      (values st (unbox (execution-symbols-box ex)))))

  (define (execute st path)
    (struct-define state st)
    (define ex (make-execution sequence path))
    (values
     (struct-copy
      state st
      [sequence (add1 sequence)]
      [executions (hash-set executions sequence ex)])
     sequence))

  (define (step st id)
    (struct-define state st)
    (let ([ex (get-execution st id)])
      (struct-define execution ex)
      (define stdout-bs (get-output-bytes pending-stdout #t))
      (define stderr-bs (get-output-bytes pending-stderr #t))
      (define the-output (ExecutionOutput stdout-bs stderr-bs))
      (define the-step ((if evaluation ExecutionStep.more ExecutionStep.done) the-output))
      (values st the-step)))

  (define (kill st id)
    (struct-define state st)
    (let ([ex (get-execution st id)])
      (struct-define execution ex)
      (when evaluation
        (break-thread evaluation)
        (thread-wait evaluation))
      (custodian-shutdown-all custodian)
      (values st (void)))))

(define (copy-bytes-avail in out)
  (define buf (make-bytes 4096))
  (let loop ()
    (define n-read (read-bytes-avail!* buf in))
    (unless (or (eof-object? n-read)
                (zero? n-read))
      (write-bytes buf out 0 n-read)
      (loop))))

(define the-executor
  (executor))

(define-rpc (execute-script [at-path path : String] : UVarint)
  (execute the-executor path))

(define-rpc (step-execution [_ id : UVarint] : ExecutionStep)
  (step the-executor id))

(define-rpc (stop-execution [_ id : UVarint])
  (kill the-executor id))

(define-rpc (get-execution-symbols [_ id : UVarint] : (Listof String))
  (map symbol->string (symbols the-executor id)))

(define callout-installed? #f)
(define-callout (on-executor-step [execution-id : UVarint]))
(define-rpc (mark-on-executor-step-installed)
  (set! callout-installed? #t))
