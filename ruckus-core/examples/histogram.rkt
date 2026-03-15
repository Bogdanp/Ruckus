#lang racket/base

(require racket/list)

;; Histogram
;;   Group scores into fixed-size bins and count each bin.
;;
;; Input data to edit:
;;   Change `scores` and `bin-size` below.

(define scores '(44 52 71 68 91 83 77 59 62 74 88 93 47 69 72 80))
(define bin-size 10)

(define (bucket-of x)
  (* bin-size (quotient x bin-size)))

(define (inc-bucket hist bucket)
  (cond
    [(null? hist) (list (list bucket 1))]
    [(= bucket (first (first hist))) (cons (list bucket (+ 1 (second (first hist)))) (rest hist))]
    [else (cons (first hist) (inc-bucket (rest hist) bucket))]))

(define (build-hist ys hist)
  (cond
    [(null? ys) hist]
    [else (build-hist (rest ys) (inc-bucket hist (bucket-of (first ys))))]))

(build-hist scores '())
