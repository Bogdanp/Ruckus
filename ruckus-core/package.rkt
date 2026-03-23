#lang racket/base

(require noise/backend
         noise/serde
         pkg/lib
         racket/list
         racket/string
         setup/dirs)

(provide
 (record-out InstalledPackage)
 (record-out CatalogPackage))

(define-record InstalledPackage
  [name : String]
  [source : String]
  [auto? : Bool])

(define-record CatalogPackage
  [name : String]
  [description : String])

(define-rpc (list-installed-packages : (Listof InstalledPackage))
  (with-pkg-lock/read-only
    (define table (installed-pkg-table #:scope 'installation))
    (for/list ([(name info) (in-hash table)])
      (InstalledPackage
       name
       (hash-ref info 'source "")
       (hash-ref info 'auto #f)))))

(define-rpc (install-package [_ source : String])
  (with-pkg-lock
    (pkg-install
     (list (pkg-desc source 'name #f #f #f))
     #:dep-behavior 'search-auto)))

(define-rpc (remove-package [_ name : String])
  (with-pkg-lock
    (pkg-remove (list name))))

(define-rpc (search-packages [_ query : String] : (Listof CatalogPackage))
  (define results (pkg-catalog-suggestions-for-module (string->symbol query)))
  (for/list ([name (in-list results)])
    (CatalogPackage name "")))
