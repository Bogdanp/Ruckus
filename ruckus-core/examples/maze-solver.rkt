#lang racket/base

(require racket/list)

;; Maze solver
;;   Find a path from S to G in an ASCII/Unicode maze and render the path.
;;
;; Input data to edit:
;;   Change `maze` below.

; S = Start
; G = Goal
(define maze
  '("┌─────────────┬─────────────┐"
    "│S            │            G│"
    "│ ┌─────┐ ┌───┴───┐ ┌─────┐ │"
    "│ │     │ │       │ │     │ │"
    "│ └─────┘ └─────┬─┘ └─────┘ │"
    "│               │           │"
    "│ ┌─────┐ ┌─────┼─────┐ ┌─┐ │"
    "│ │     │ │               │ │"
    "├─┼───┐ │ │ ┌─────┬─────┐ │ ├"
    "│ │   │ │ │ │     │     │ │ │"
    "│ │   └─┘ │ └─────┼─────┘ │ │"
    "│ │       │               │ │"
    "│ └─────┐ │ ┌─────┬─────┐ │ │"
    "│       │ │ │     │     │ │ │"
    "│ ┌─────┘ └───┼───┼─────┘ │ │"
    "│ │           │           │ │"
    "│ └─────┐ ┌───┼───┐ ┌─────┘ │"
    "│       │ │       │ │       │"
    "│ ┌─────┘ └───────┘ └─────┐ │"
    "│                         │ │"
    "└───────────────────────────┘"))

(define height (length maze))
(define width
  (cond
    [(null? maze) 0]
    [else (string-length (first maze))]))

(define (cell-at cell)
  (string-ref (list-ref maze (second cell)) (first cell)))

(define (inside? cell)
  (and (<= 0 (first cell)) (< (first cell) width) (<= 0 (second cell)) (< (second cell) height)))

(define wall-chars '(#\─ #\│ #\┌ #\┐ #\└ #\┘ #\├ #\┤ #\┬ #\┴ #\┼))

(define (wall? ch)
  (member ch wall-chars))

(define (blocked? cell)
  (wall? (cell-at cell)))

(define (find-marker marker)
  (let loopy ([y 0])
    (cond
      [(= y height) #f]
      [else
       (let loopx ([x 0])
         (cond
           [(= x width) (loopy (+ y 1))]
           [(char=? (string-ref (list-ref maze y) x) marker) (list x y)]
           [else (loopx (+ x 1))]))])))

(define start (find-marker #\S))
(define goal (find-marker #\G))

(define (neighbors cell)
  (define x (first cell))
  (define y (second cell))
  (define candidates (list (list (+ x 1) y) (list (- x 1) y) (list x (+ y 1)) (list x (- y 1))))
  (let loop ([cs candidates])
    (cond
      [(null? cs) '()]
      [(and (inside? (first cs)) (not (blocked? (first cs)))) (cons (first cs) (loop (rest cs)))]
      [else (loop (rest cs))])))

(define (enqueue-neighbors ns path q seen-now)
  (cond
    [(null? ns) (list q seen-now)]
    [else
     (define n (first ns))
     (cond
       [(member n seen-now) (enqueue-neighbors (rest ns) path q seen-now)]
       [else (enqueue-neighbors (rest ns) path (append q (list (cons n path))) (cons n seen-now))])]))

(define (solve queue seen)
  (cond
    [(null? queue) #f]
    [else
     (define path (first queue))
     (define node (first path))
     (cond
       [(equal? node goal) (reverse path)]
       [else
        (define state (enqueue-neighbors (neighbors node) path (rest queue) seen))
        (define new-queue (first state))
        (define new-seen (second state))
        (solve new-queue new-seen)])]))

(define (path-cell? c path)
  (and path (member c path)))

(define (render-cell cell path)
  (cond
    [(equal? cell start) #\S]
    [(equal? cell goal) #\G]
    [(wall? (cell-at cell)) (cell-at cell)]
    [(path-cell? cell path) #\*]
    [else #\.]))

(define (render-row y path)
  (let loop ([x 0])
    (cond
      [(= x width) '()]
      [else (cons (render-cell (list x y) path) (loop (+ x 1)))])))

(define (join-lines lines)
  (cond
    [(null? lines) ""]
    [(null? (rest lines)) (first lines)]
    [else (string-append (first lines) "\n" (join-lines (rest lines)))]))

(define (render-maze path)
  (let loop ([y 0])
    (cond
      [(= y height) '()]
      [else (cons (list->string (render-row y path)) (loop (+ y 1)))])))

(define path
  (cond
    [(and start goal) (solve (list (list start)) (list start))]
    [else #f]))

(cond
  [path (displayln (join-lines (render-maze path)))]
  [else "No path found."])
