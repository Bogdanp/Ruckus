#lang racket/base

;; Compute the set of packages needed by the given root packages.
;; Outputs the names of UNNEEDED installed packages (one per line).
;;
;; Handles root packages that aren't locally installed by fetching
;; their dependencies from the package catalog.
;;
;; Usage: racket bin/compute-needed-pkgs.rkt root-pkg ...

(require pkg/lib
         racket/cmdline
         racket/set
         setup/getinfo)

(define root-pkgs
  (command-line
   #:args pkgs
   pkgs))

(define (dep-name dep)
  (cond
    [(string? dep) dep]
    [(pair? dep) (car dep)]
    [else (format "~a" dep)]))

(define (local-deps name)
  (define dir (pkg-directory name))
  (cond
    [dir
     (define get-info (get-info/full dir))
     (cond
       [get-info (map dep-name (get-info 'deps (lambda () '())))]
       [else '()])]
    [else #f]))

(define (catalog-deps name)
  (define details (get-pkg-details-from-catalogs name))
  (cond
    [details (map dep-name (hash-ref details 'dependencies '()))]
    [else '()]))

(define (pkg-deps name)
  (or (local-deps name)
      (catalog-deps name)))

(parameterize ([current-pkg-scope 'installation])
  (define installed (list->set (hash-keys (installed-pkg-table))))
  (define needed
    (let loop ([queue root-pkgs]
               [seen (list->set root-pkgs)])
      (cond
        [(null? queue) seen]
        [else
         (define new-deps
           (for/list ([dep (in-list (pkg-deps (car queue)))]
                      #:when (set-member? installed dep)
                      #:unless (set-member? seen dep))
             dep))
         (loop (append (cdr queue) new-deps)
               (set-union seen (list->set new-deps)))])))
  (for ([name (in-set (set-subtract installed needed))])
    (displayln name)))
