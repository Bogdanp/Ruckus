#lang racket/base

(require racket/list)

;; Matrix multiply
;;   Multiply matrix A by matrix B.
;;
;; Input data to edit:
;;   Change matrices `A` and `B` below.

(define A '((1 2 3) (4 5 6)))
(define B '((7 8) (9 10) (11 12)))

(define (column m j)
  (cond
    [(null? m) '()]
    [else (cons (list-ref (first m) j) (column (rest m) j))]))

(define (transpose m)
  (cond
    [(null? m) '()]
    [else
     (define cols (length (first m)))
     (let loop ([j 0])
       (cond
         [(= j cols) '()]
         [else (cons (column m j) (loop (+ j 1)))]))]))

(define (dot xs ys)
  (cond
    [(null? xs) 0]
    [else (+ (* (first xs) (first ys)) (dot (rest xs) (rest ys)))]))

(define (mul-row row cols)
  (cond
    [(null? cols) '()]
    [else (cons (dot row (first cols)) (mul-row row (rest cols)))]))

(define (matmul a b)
  (define bt (transpose b))
  (let loop ([rows a])
    (cond
      [(null? rows) '()]
      [else (cons (mul-row (first rows) bt) (loop (rest rows)))])))

(matmul A B)
