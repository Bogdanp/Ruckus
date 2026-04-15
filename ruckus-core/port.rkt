#lang racket/base

(provide copy-bytes-avail)

(define (copy-bytes-avail in out)
  (define buf (make-bytes 4096))
  (let loop ()
    (define n-read (read-bytes-avail!* buf in))
    (unless (or (eof-object? n-read)
                (zero? n-read))
      (write-bytes buf out 0 n-read)
      (loop))))
