#lang racket/base

(require racket/list)

;; Continuation demo (call/cc + dynamic-wind)
;;   Exit early when a value is found and trace dynamic-wind enter/leave.
;;
;; Input data to edit:
;;   Change `data`, `target`, and `trace?` below.

(define data '(3 7 11 18 24 31))
(define target 18)
(define trace? #t)

(define trace-log '())

(define (note x)
  (cond
    [trace? (set! trace-log (cons x trace-log))]
    [else 'ok]))

(define (find-first xs wanted)
  (call/cc
   (lambda (exit)
     (dynamic-wind
       (lambda () (note 'enter))
       (lambda ()
         (let loop ([ys xs])
           (cond
             [(null? ys) #f]
             [(= (first ys) wanted) (exit (first ys))]
             [else (loop (rest ys))])))
       (lambda () (note 'leave))))))

(list
 (list 'found (find-first data target))
 (list 'trace (reverse trace-log)))
