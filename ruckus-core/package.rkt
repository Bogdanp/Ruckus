#lang racket/base

(require actor
         noise/backend
         noise/serde
         pkg/lib
         racket/hash
         racket/match
         ruckus/openssl
         struct-define)

(provide
 (record-out CatalogPackage)
 (enum-out PackageSource)
 (record-out InstalledPackage)
 (record-out InstallOutput)
 (enum-out InstallStep))

(define BUFSIZE (* 64 1024))

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

(struct install-state (sequence installs))
(struct install (id source custodian thread error-box stdout stderr pending-stdout pending-stderr gc-deadline))

(define (make-install-state)
  (install-state
   #;sequence 0
   #;installs (hasheqv)))

(define (make-gc-deadline)
  (+ (current-inexact-monotonic-milliseconds)
     (* 60 1000)))

(define (make-install id source)
  (define error-box (box #f))
  (define custodian (make-custodian))
  (parameterize ([current-custodian custodian])
    (define-values (stdout-in stdout-out) (make-pipe BUFSIZE))
    (define-values (stderr-in stderr-out) (make-pipe BUFSIZE))
    (define worker
      (parameterize ([current-output-port stdout-out]
                     [current-error-port stderr-out])
        (thread
         (lambda ()
           (with-handlers ([exn:fail?
                            (lambda (e)
                              (set-box! error-box (exn-message e)))])
             (parameterize ([current-pkg-scope 'installation])
               (with-pkg-lock
                 (pkg-install
                  (list (pkg-desc source 'name #f #f #f))
                  #:dep-behavior 'search-auto))))
           (close-output-port stdout-out)
           (close-output-port stderr-out)))))
    (install
     #;id id
     #;source source
     #;custodian custodian
     #;thread worker
     #;error-box error-box
     #;stdout stdout-in
     #;stderr stderr-in
     #;pending-stdout (open-output-bytes)
     #;pending-stderr (open-output-bytes)
     #;gc-deadline #f)))

(define-actor (installer)
  #:state (make-install-state)
  #:event (lambda (st)
            (apply
             choice-evt
             (handle-evt
              (alarm-evt
               (make-gc-deadline)
               #;monotonic? #t)
              (lambda (_)
                (define now (current-inexact-monotonic-milliseconds))
                (struct-copy
                 install-state st
                 [installs
                  (hash-filter-values
                   (install-state-installs st)
                   (lambda (ins)
                     (struct-define install ins)
                     (or thread (gc-deadline . > . now))))])))
             (for/list ([ins (in-hash-values (install-state-installs st))])
               (struct-define install ins)
               (choice-evt
                (handle-evt
                 (if thread (thread-dead-evt thread) never-evt)
                 (lambda (_)
                   (struct-define install-state st)
                   (custodian-shutdown-all custodian)
                   (define updated-install
                     (struct-copy
                      install ins
                      [thread #f]
                      [gc-deadline (make-gc-deadline)]))
                   (when callout-installed?
                     (on-install-step id))
                   (struct-copy
                    install-state st
                    [installs (hash-set installs id updated-install)])))
                (handle-evt
                 (choice-evt stdout stderr)
                 (lambda (src)
                   (define dst
                     (if (eq? src stdout)
                         pending-stdout
                         pending-stderr))
                   (copy-bytes-avail src dst)
                   (when callout-installed?
                     (on-install-step id))
                   st))))))

  (define/private (get-install st id)
    (hash-ref
     #;ht (install-state-installs st)
     #;key id
     #;failure-result
     (lambda ()
       (error 'get-install "install ~s not found" id))))

  (define (start st source)
    (struct-define install-state st)
    (define ins (make-install sequence source))
    (values
     (struct-copy
      install-state st
      [sequence (add1 sequence)]
      [installs (hash-set installs sequence ins)])
     sequence))

  (define (step st id)
    (let ([ins (get-install st id)])
      (struct-define install ins)
      (define stdout-bs (get-output-bytes pending-stdout #t))
      (define stderr-bs (get-output-bytes pending-stderr #t))
      (define the-output (InstallOutput stdout-bs stderr-bs))
      (define err (unbox error-box))
      (define the-step
        (cond
          [thread (InstallStep.more the-output)]
          [err    (InstallStep.failed the-output err)]
          [else   (InstallStep.done the-output)]))
      (values st the-step)))

  (define (kill st id)
    (let ([ins (get-install st id)])
      (struct-define install ins)
      (when thread
        (break-thread thread)
        (thread-wait thread))
      (custodian-shutdown-all custodian)
      (values st (void)))))

(define (copy-bytes-avail in out)
  (define buf (make-bytes 4096))
  (let loop ()
    (define n-read (read-bytes-avail!* buf in))
    (unless (or (eof-object? n-read)
                (zero? n-read))
      (write-bytes buf out 0 n-read)
      (loop))))

(define the-installer
  (installer))

(define-rpc (start-install-package [_ source : String] : UVarint)
  (start the-installer source))

(define-rpc (step-install [_ id : UVarint] : InstallStep)
  (step the-installer id))

(define-rpc (stop-install [_ id : UVarint])
  (kill the-installer id))

(define callout-installed? #f)
(define-callout (on-install-step [install-id : UVarint]))
(define-rpc (mark-on-install-step-installed)
  (set! callout-installed? #t))
