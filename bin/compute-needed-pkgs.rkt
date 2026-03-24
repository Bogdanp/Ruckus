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

(define (catalog-deps name)
  (define details (get-pkg-details-from-catalogs name))
  (cond
    [details
     (define deps (hash-ref details 'dependencies '()))
     (for/list ([dep (in-list deps)])
       (cond
         [(string? dep) dep]
         [(pair? dep) (car dep)]
         [else (format "~a" dep)]))]
    [else '()]))

(define (local-deps name)
  (define dir (pkg-directory name))
  (cond
    [dir
     (define get-info (get-info/full dir))
     (cond
       [get-info
        (define deps (get-info 'deps (lambda () '())))
        (for/list ([dep (in-list deps)])
          (cond
            [(string? dep) dep]
            [(pair? dep) (car dep)]
            [else (format "~a" dep)]))]
       [else '()])]
    [else #f]))

(define (pkg-deps name)
  (or (local-deps name)
      (catalog-deps name)))

(define (transitive-closure roots)
  (define installed (list->set (hash-keys (installed-pkg-table))))
  (let loop ([queue roots]
             [seen (list->set roots)])
    (cond
      [(null? queue) seen]
      [else
       (define name (car queue))
       (define deps (pkg-deps name))
       (define new-deps
         (for/list ([dep (in-list deps)]
                    #:when (set-member? installed dep)
                    #:unless (set-member? seen dep))
           dep))
       (loop (append (cdr queue) new-deps)
             (set-union seen (list->set new-deps)))])))

(parameterize ([current-pkg-scope 'installation])
  (define needed (transitive-closure root-pkgs))
  (define all-installed (list->set (hash-keys (installed-pkg-table))))
  (define unneeded (set-subtract all-installed needed))
  (for ([name (in-set unneeded)])
    (displayln name)))
