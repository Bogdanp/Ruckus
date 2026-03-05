#lang racket/base

(require racket/match
         racket/path)

(provide
 make-collects-resolver)

(define debug
  (if #f
      void
      (lambda (message . args)
        (eprintf "collects-resolver: ~a" (apply format message args)))))

;; In an embedded module, compiler-lib replaces the module name resolver
;; with a custom resolver that references embedded modules. When
;; executing user-provided code, we want to instantiate fresh modules
;; from <collects> (or <pkgs>).
;;
;; There's no way to get the original module name resolver, but the
;; embedded resolver calls it when provided an absolute module path, so
;; this resolver converts module paths to file paths before calling the
;; embedded resolver, which causes the embedded resolver to call the
;; original resolver.
(define (make-collects-resolver)
  (define orig (current-module-name-resolver))
  (case-lambda
    [(mod ns)
     (orig mod ns)]
    [(mod relto stx load?)
     (define collects-mod (or (module-path->collects-path mod relto) mod))
     (define actual-mod (or collects-mod mod))
     (unless (or collects-mod (is-#%? collects-mod))
       (debug "fallthrough ~s (relto: ~s)~n" mod relto))
     (orig actual-mod relto stx load?)]))

(define (module-path->collects-path mod relto)
  (match mod
    [(? path? p)
     `(file ,(path->string (simplify-path p)))]
    [(? symbol? mod)
     (lib-path->file-path (symbol->string mod))]
    [(? string? (not (or "." "..")))
     #:when relto
     (define relto-path
       (match (resolved-module-path-name relto)
         [(? path? p) p]
         [(cons (? path? p) _) p]
         [_ #f]))
     (and relto-path
          (let ([mod-path (simplify-path (build-path (path-only relto-path) mod))])
            `(file ,(path->string mod-path))))]
    [`(lib ,(? string? path))
     (lib-path->file-path path)]
    [`(submod ,root-module-path ,submod-path-element ...)
     (define collects-mod (module-path->collects-path root-module-path relto))
     (and collects-mod `(submod ,collects-mod ,@submod-path-element))]
    [_
     #f]))

(define (lib-path->file-path path-str)
  (with-handlers ([exn:fail? (lambda (_) #f)])
    (define parts (regexp-split #rx"/" path-str))
    (define-values (collections file)
      (match parts
        [`(,collection) (values (list collection) "main.rkt")]
        [`(,collections ... ,module-name)
         (define module-name+ext
           (if (regexp-match? #rx"\\." module-name)
               module-name
               (path-add-extension module-name #".rkt")))
         (values collections module-name+ext)]))
    `(file ,(path->string (apply collection-file-path file collections)))))

(define (is-#%? mod)
  (match mod
    [`(quote ,(? symbol? s))
     (regexp-match? #rx"^#%" (symbol->string s))]
    [_ #f]))
