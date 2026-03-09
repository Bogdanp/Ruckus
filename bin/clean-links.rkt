#lang racket/base

(require racket/cmdline
         racket/match)

(define links.rktd
  (command-line
   #:args [path]
   path))

(define links
  (call-with-input-file links.rktd read))
(define filtered-links
  (filter
   values
   (for/list ([l (in-list links)])
     (match l
       [`(,_ (#"pkgs" ,_ ...)) l]
       [_ #f]))))
(call-with-output-file links.rktd
  #:exists 'replace
  (lambda (out)
    (write filtered-links out)))
