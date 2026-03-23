#lang racket/base

(require racket/cmdline
         racket/match
         racket/path)

(define links.rktd
  (command-line
   #:args [path]
   path))

(define pkgs.rktd
  (build-path (path-only links.rktd) "pkgs" "pkgs.rktd"))

(define (->string v)
  (if (string? v) v (bytes->string/utf-8 v)))

(define (make-pkg-path . names)
  (apply build-path dir "pkgs" (map ->string names)))

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
        (define pkg-path (apply make-pkg-path names))
        (and (directory-exists? pkg-path) l)]
       [_ #f]))))
(call-with-output-file links.rktd
  #:exists 'replace
  (lambda (out)
    (write filtered-links out)))

(define pkgs
  (call-with-input-file pkgs.rktd read))
(define filtered-pkgs
  (for/hash ([(name info) (in-hash pkgs)]
             #:when (directory-exists? (make-pkg-path name)))
    (values name info)))
(call-with-output-file pkgs.rktd
  #:exists 'replace
  (lambda (out)
    (write filtered-pkgs out)))
