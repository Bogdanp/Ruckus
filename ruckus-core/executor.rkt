#lang racket/base

(require actor
         noise/backend
         noise/serde
         struct-define)

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
(struct execution (id path custodian evaluation stdout stderr pending-stdout pending-stderr))

(define (make-state)
  (state
   #;sequence 0
   #;executions (hasheqv)))

(define (make-execution id path)
  (define custodian (make-custodian))
  (parameterize ([current-custodian custodian])
    (define-values (stdout-in stdout-out) (make-pipe))
    (define-values (stderr-in stderr-out) (make-pipe))
    (define evaluation
      (parameterize ([current-output-port stdout-out]
                     [current-error-port stderr-out])
        (thread
         (lambda ()
           (with-handlers ([exn?
                            (lambda (e)
                              ((error-display-handler)
                               (format "~a" (exn-message e))
                               e))])
             (dynamic-require `(file ,path) #f))))))
    (execution
     #;id id
     #;path path
     #;custodian custodian
     #;evaluation evaluation
     #;stdout stdout-in
     #;stderr stderr-in
     #;pending-stdout (open-output-bytes)
     #;pending-stderr (open-output-bytes))))

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

  (define (kill st id)
    (struct-define state st)
    (let ([ex (hash-ref executions id)])
      (struct-define execution ex)
      (custodian-shutdown-all custodian)
      (values st (void))))

  (define (step st id)
    (struct-define state st)
    (let ([ex (hash-ref executions id)])
      (struct-define execution ex)
      (define stdout-bs (get-output-bytes pending-stdout #t))
      (define stderr-bs (get-output-bytes pending-stderr #t))
      (define the-output (ExecutionOutput stdout-bs stderr-bs))
      (define the-step ((if evaluation ExecutionStep.more ExecutionStep.done) the-output))
      (values st the-step)))

  (define (execute st path)
    (struct-define state st)
    (define ex (make-execution sequence path))
    (values
     (struct-copy
      state st
      [sequence (add1 sequence)]
      [executions (hash-set executions sequence ex)])
     sequence)))

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

(define callout-installed? #f)
(define-callout (on-executor-step [execution-id : UVarint]))
(define-rpc (mark-on-executor-step-installed)
  (set! callout-installed? #t))
