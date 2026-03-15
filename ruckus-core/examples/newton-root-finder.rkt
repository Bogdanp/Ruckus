#lang racket/base

;; Newton root finder
;;   Solve `f(x) = 0` using Newton's method.
;;
;; Input data to edit:
;;   Change `target`, `guess`, `tolerance`, and `max-steps` below.

;; Let's solve `x^2 - 2 = 0` to find the square root of two.

(define (f x)
  (- (* x x) target))

(define (df x) ; the derivative of f
  (* 2.0 x))

(define target 2.0) ; solve f(x) = target
(define guess 1.0) ; initial guess for a root
(define tolerance 0.000001)
(define max-steps 20)

(define (newton x step)
  (define fx (f x))
  (cond
    [(or (= step max-steps) (< (abs fx) tolerance)) x]
    [else (newton (- x (/ fx (df x))) (+ step 1))]))

(define root (newton guess 0))
(list (list 'root root) (list 'f-at-root (f root)))
