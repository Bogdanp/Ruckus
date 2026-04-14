#lang racket/base

;; Generic actor for worker threads whose stdout/stderr is captured via
;; pipes and streamed back through a callout.  Both the script executor
;; and the package installer build on this: each one supplies a
;; thread-constructor that runs with `current-output-port` /
;; `current-error-port` parameterized to the actor's pipes, plus any
;; per-job state (e.g. a symbols box, or an error box) that callers can
;; read via `streaming-peek`.

(require actor
         racket/hash
         struct-define)

(provide
 BUFSIZE
 (struct-out streaming-output)
 streaming-actor
 streaming-start
 streaming-step
 streaming-stop
 streaming-peek)

(define BUFSIZE (* 64 1024))

(struct streaming-state (sequence jobs))
(struct job (id extra custodian thread stdout stderr pending-stdout pending-stderr gc-deadline))

;; A snapshot returned by `streaming-step`.  `extra` is whatever the
;; job's thread-constructor stashed as its second return value.
(struct streaming-output (stdout stderr done? extra))

(define (make-gc-deadline)
  (+ (current-inexact-monotonic-milliseconds)
     (* 60 1000)))

(define (copy-bytes-avail in out)
  (define buf (make-bytes 4096))
  (let loop ()
    (define n-read (read-bytes-avail!* buf in))
    (unless (or (eof-object? n-read)
                (zero? n-read))
      (write-bytes buf out 0 n-read)
      (loop))))

;; `make-worker` is a thunk that runs with stdout/stderr pipes
;; parameterized into `current-output-port`/`current-error-port` and
;; returns (values thread extra).
(define (make-job id make-worker)
  (define custodian (make-custodian))
  (parameterize ([current-custodian custodian])
    (define-values (stdout-in stdout-out) (make-pipe BUFSIZE))
    (define-values (stderr-in stderr-out) (make-pipe BUFSIZE))
    (define-values (worker-thread extra)
      (parameterize ([current-output-port stdout-out]
                     [current-error-port stderr-out])
        (make-worker)))
    (job id extra custodian worker-thread stdout-in stderr-in
         (open-output-bytes) (open-output-bytes) #f)))

(define-actor (streaming-actor notify!)
  #:state (streaming-state 0 (hasheqv))
  #:event (lambda (st)
            (apply
             choice-evt
             (handle-evt
              (alarm-evt (make-gc-deadline) #;monotonic? #t)
              (lambda (_)
                (define now (current-inexact-monotonic-milliseconds))
                (struct-copy
                 streaming-state st
                 [jobs
                  (hash-filter-values
                   (streaming-state-jobs st)
                   (lambda (j)
                     (struct-define job j)
                     (or thread (gc-deadline . > . now))))])))
             (for/list ([j (in-hash-values (streaming-state-jobs st))])
               (struct-define job j)
               (choice-evt
                (handle-evt
                 (if thread (thread-dead-evt thread) never-evt)
                 (lambda (_)
                   (struct-define streaming-state st)
                   ;; Drain any buffered output before tearing down the
                   ;; pipes — otherwise the worker's tail output is lost
                   ;; when the custodian closes the read ends.
                   (copy-bytes-avail stdout pending-stdout)
                   (copy-bytes-avail stderr pending-stderr)
                   (custodian-shutdown-all custodian)
                   (notify! id)
                   (struct-copy
                    streaming-state st
                    [jobs (hash-set
                           jobs id
                           (struct-copy
                            job j
                            [thread #f]
                            [gc-deadline (make-gc-deadline)]))])))
                (handle-evt
                 (choice-evt stdout stderr)
                 (lambda (src)
                   (define dst (if (eq? src stdout) pending-stdout pending-stderr))
                   (copy-bytes-avail src dst)
                   (notify! id)
                   st))))))

  (define/private (get-job-for st id)
    (hash-ref
     (streaming-state-jobs st) id
     (lambda () (error 'streaming-actor "job ~s not found" id))))

  (define (streaming-start st make-worker)
    (struct-define streaming-state st)
    (define j (make-job sequence make-worker))
    (values
     (struct-copy
      streaming-state st
      [sequence (add1 sequence)]
      [jobs (hash-set jobs sequence j)])
     sequence))

  (define (streaming-step st id)
    (let ([j (get-job-for st id)])
      (struct-define job j)
      (define stdout-bs (get-output-bytes pending-stdout #t))
      (define stderr-bs (get-output-bytes pending-stderr #t))
      (values st (streaming-output stdout-bs stderr-bs (not thread) extra))))

  (define (streaming-stop st id)
    (let ([j (get-job-for st id)])
      (struct-define job j)
      (when thread
        (break-thread thread)
        (thread-wait thread))
      (custodian-shutdown-all custodian)
      (values st (void))))

  (define (streaming-peek st id)
    (let ([j (get-job-for st id)])
      (struct-define job j)
      (values st extra))))
