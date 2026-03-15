#lang racket/base

(require racket/list)

;; BFS shortest path
;;   Find a shortest path between source and target in an unweighted graph.
;;
;; Input data to edit:
;;   Change `graph`, `source`, and `target` below.

(define graph
  '((A (B C))
    (B (A D E))
    (C (A F))
    (D (B G))
    (E (B G H))
    (F (C H))
    (G (D E I))
    (H (E F I))
    (I (G H))))
(define source 'A)
(define target 'I)

(define (neighbors node g)
  (define entry (assoc node g))
  (cond
    [entry (second entry)]
    [else '()]))

(define (enqueue-neighbors ns path q seen-now)
  (cond
    [(null? ns) (list q seen-now)]
    [else
     (define n (first ns))
     (cond
       [(member n seen-now) (enqueue-neighbors (rest ns) path q seen-now)]
       [else (enqueue-neighbors (rest ns) path (append q (list (cons n path))) (cons n seen-now))])]))

(define (bfs queue seen)
  (cond
    [(null? queue) #f]
    [else
     (define path (first queue))
     (define node (first path))
     (cond
       [(eq? node target) (reverse path)]
       [else
        (define state (enqueue-neighbors (neighbors node graph) path (rest queue) seen))
        (define new-queue (first state))
        (define new-seen (second state))
        (bfs new-queue new-seen)])]))

(bfs (list (list source)) (list source))
