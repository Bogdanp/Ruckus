#lang racket/base

(require noise/backend
         noise/serde
         pkg/lib
         racket/match
         ruckus/openssl
         "streaming-actor.rkt")

(provide
 (record-out CatalogPackage)
 (enum-out PackageSource)
 (record-out InstalledPackage)
 (record-out InstallOutput)
 (enum-out InstallStep))

(define-record CatalogPackage
  [name : String])

(define-enum PackageSource
  [catalog {name : String}]
  [catalog-with-source {name : String} {source : String}]
  [url {url : String}]
  [git {url : String}]
  [file {path : String}]
  [dir {path : String}]
  [link {path : String}]
  [static-link {path : String}]
  [clone {name : String} {source : String}])

(define-record InstalledPackage
  [name : String]
  [source : PackageSource]
  [checksum : (Optional String)]
  [auto? : Bool])

(define-record InstallOutput
  [stdout : Bytes]
  [stderr : Bytes])

(define-enum InstallStep
  [done {output : InstallOutput}]
  [failed {output : InstallOutput} {message : String}]
  [more {output : InstallOutput}])

(define (pkg-source->PackageSource source)
  (match source
    [`(catalog ,name) (PackageSource.catalog name)]
    [`(catalog ,name ,source) (PackageSource.catalog-with-source name source)]
    [`(url ,url) (PackageSource.url url)]
    [`(git ,url) (PackageSource.git url)]
    [`(file ,path) (PackageSource.file path)]
    [`(dir ,path) (PackageSource.dir path)]
    [`(link ,path) (PackageSource.link path)]
    [`(static-link ,path) (PackageSource.static-link path)]
    [`(clone ,name ,source) (PackageSource.clone name source)]))

(define-rpc (list-installed-packages : (Listof InstalledPackage))
  (parameterize ([current-pkg-scope 'installation])
    (with-pkg-lock/read-only
      (define table (installed-pkg-table))
      (for/list ([(name info) (in-hash table)])
        (match-define (pkg-info src checksum auto?) info)
        (InstalledPackage name (pkg-source->PackageSource src) checksum auto?)))))

(define-rpc (remove-package [_ name : String])
  (parameterize ([current-pkg-scope 'installation])
    (with-pkg-lock
      (pkg-remove (list name)))))

(define-rpc (remove-orphaned-packages)
  (parameterize ([current-pkg-scope 'installation])
    (with-pkg-lock
      (pkg-remove null #:auto? #t))))

(define-rpc (search-packages [_ query : String] : (Listof CatalogPackage))
  (for/list ([name (in-list (get-all-pkg-names-from-catalogs))]
             #:when (regexp-match? (format "^(?i:~a)" (regexp-quote query)) name))
    (CatalogPackage name)))

;; --- Streaming install ---------------------------------------------------

(define callout-installed? #f)
(define-callout (on-install-step [install-id : UVarint]))
(define-rpc (mark-on-install-step-installed)
  (set! callout-installed? #t))

(define (notify-step id)
  (when callout-installed?
    (on-install-step id)))

(define the-installer
  (streaming-actor notify-step))

(define (install-worker source)
  (define error-box (box #f))
  (define worker
    (thread
     (lambda ()
       (with-handlers ([exn:fail?
                        (lambda (e)
                          (set-box! error-box (exn-message e)))])
         (parameterize ([current-pkg-scope 'installation])
           (with-pkg-lock
             (pkg-install
              (list (pkg-desc source 'name #f #f #f))
              #:dep-behavior 'search-auto)))))))
  (values worker error-box))

(define-rpc (start-install-package [_ source : String] : UVarint)
  (streaming-start the-installer (lambda () (install-worker source))))

(define-rpc (step-install [_ id : UVarint] : InstallStep)
  (define out (streaming-step the-installer id))
  (define the-output (InstallOutput (streaming-output-stdout out)
                                    (streaming-output-stderr out)))
  (define err (unbox (streaming-output-extra out)))
  (cond
    [(not (streaming-output-done? out)) (InstallStep.more the-output)]
    [err (InstallStep.failed the-output err)]
    [else (InstallStep.done the-output)]))

(define-rpc (stop-install [_ id : UVarint])
  (streaming-stop the-installer id))
