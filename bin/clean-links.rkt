#lang racket/base

(require racket/cmdline
         racket/match)

(define links.rktd
  (command-line
   #:args [path]
   path))

(define-values (dir _name _is-dir?)
  (split-path links.rktd))
(define links
  (call-with-input-file links.rktd read))
(define filtered-links
  (filter
   values
   (for/list ([l (in-list links)])
     (match l
       [`(,_ (#"pkgs" ,names ...))
        (define pkg-path (apply build-path dir "pkgs" (map bytes->string/utf-8 names)))
        (and (directory-exists? pkg-path) l)]
       [_ #f]))))
(call-with-output-file links.rktd
  #:exists 'replace
  (lambda (out)
    (write filtered-links out)))
