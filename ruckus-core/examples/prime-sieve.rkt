#lang racket/base

(require racket/list)

;; Prime sieve up to N
;;   Compute all primes from 2 up to a limit.
;;
;; Input data to edit:
;;   Change `limit` below.

(define limit 100)

(define (range from to)
  (cond
    [(> from to) '()]
    [else (cons from (range (+ from 1) to))]))

(define (remove-multiples p xs)
  (cond
    [(null? xs) '()]
    [(= (remainder (first xs) p) 0) (remove-multiples p (rest xs))]
    [else (cons (first xs) (remove-multiples p (rest xs)))]))

(define (sieve xs)
  (cond
    [(null? xs) '()]
    [else (cons (first xs) (sieve (remove-multiples (first xs) (rest xs))))]))

(cond
  [(< limit 2) '()]
  [else (sieve (range 2 limit))])
