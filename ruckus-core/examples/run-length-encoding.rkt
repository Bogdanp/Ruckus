#lang racket/base

(require racket/list)

;; Run-length encode/decode
;;   Encode repeated values as (value count) pairs, or decode them.
;;
;; Input data to edit:
;;   Change `mode` and `input` below.

(define mode 'encode) ; set to 'decode to decode input
(define input '(a a a b b c c c c d a a))

(define (replicate x n)
  (cond
    [(= n 0) '()]
    [else (cons x (replicate x (- n 1)))]))

(define (decode pairs)
  (cond
    [(null? pairs) '()]
    [else (append (replicate (first (first pairs)) (second (first pairs))) (decode (rest pairs)))]))

(define (encode xs)
  (define (finish value count acc)
    (cons (list value count) acc))
  (let loop ([ys xs]
             [current #f]
             [count 0]
             [acc '()])
    (cond
      [(null? ys)
       (if (= count 0)
           (reverse acc)
           (reverse (finish current count acc)))]
      [(= count 0) (loop (rest ys) (first ys) 1 acc)]
      [(equal? (first ys) current) (loop (rest ys) current (+ count 1) acc)]
      [else (loop (rest ys) (first ys) 1 (finish current count acc))])))

(cond
  [(eq? mode 'encode) (encode input)]
  [else (decode input)])
