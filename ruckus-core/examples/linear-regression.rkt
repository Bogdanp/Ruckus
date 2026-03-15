#lang racket/base

(require racket/list)

;; Linear regression (least squares)
;;   Fit a line y = slope*x + intercept to data points.
;;
;; Input data to edit:
;;   Change `points` below.

(define points '((1 1.4) (2 1.9) (3 3.2) (4 3.8) (5 5.1) (6 5.9)))

(define (sum f xs)
  (apply + (map f xs)))

(define n (length points))
(define sx (sum first points))
(define sy (sum second points))
(define sxx (sum (lambda (p) (* (first p) (first p))) points))
(define sxy (sum (lambda (p) (* (first p) (second p))) points))
(define denom (- (* n sxx) (* sx sx)))
(define slope (/ (- (* n sxy) (* sx sy)) denom))
(define intercept (/ (- sy (* slope sx)) n))

(list (list 'slope slope) (list 'intercept intercept))
