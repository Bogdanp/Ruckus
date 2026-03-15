#lang racket/base

(require racket/list)

;; List statistics
;;   Compute count, sum, mean, minimum, and maximum for a list of numbers.
;;
;; Input data to edit:
;;   Change `xs` below to analyze a different dataset.

(define xs '(12 7 5 22 9 13 18 4 11))

(define (sum-list ys)
  (cond
    [(null? ys) 0]
    [else (+ (first ys) (sum-list (rest ys)))]))

(define (min-list ys)
  (cond
    [(null? (rest ys)) (first ys)]
    [else
     (define m (min-list (rest ys)))
     (if (< (first ys) m)
         (first ys)
         m)]))

(define (max-list ys)
  (cond
    [(null? (rest ys)) (first ys)]
    [else
     (define m (max-list (rest ys)))
     (if (> (first ys) m)
         (first ys)
         m)]))

(define (list-statistics xs)
  (define n (length xs))
  (define total (sum-list xs))
  (define lo (min-list xs))
  (define hi (max-list xs))
  (define mean (/ total n))
  (list (list 'count n) (list 'sum total) (list 'mean mean) (list 'min lo) (list 'max hi)))

(list-statistics xs)
