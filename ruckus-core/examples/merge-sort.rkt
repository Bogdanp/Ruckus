#lang racket/base

(require racket/list)

;; Merge sort
;;   Sort a list of numbers using merge sort.
;;
;; Input data to edit:
;;   Change `xs` below.

(define xs '(22 7 1 45 3 12 9 18 6 30))

(define (split ys)
  (cond
    [(or (null? ys) (null? (rest ys))) (list ys '())]
    [else
     (define parts (split (rest (rest ys))))
     (list (cons (first ys) (first parts)) (cons (second ys) (second parts)))]))

(define (merge left right)
  (cond
    [(null? left) right]
    [(null? right) left]
    [(<= (first left) (first right)) (cons (first left) (merge (rest left) right))]
    [else (cons (first right) (merge left (rest right)))]))

(define (merge-sort ys)
  (cond
    [(or (null? ys) (null? (rest ys))) ys]
    [else
     (define parts (split ys))
     (define left (first parts))
     (define right (second parts))
     (merge (merge-sort left) (merge-sort right))]))

(merge-sort xs)
