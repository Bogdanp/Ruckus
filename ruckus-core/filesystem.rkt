#lang racket/base

(require noise/backend
         noise/serde
         (prefix-in base: racket/base)
         (prefix-in base: racket/file)
         racket/file
         racket/path
         racket/promise
         "appdata.rkt"
         "example.rkt")

(provide
 (record-out File)
 (record-out Folder)
 (enum-out FilesystemEntry))

(define files-path
  (delay/sync
   (define path (build-application-path "files"))
   (make-directory* path)
   path))

(define examples-path
  (delay/sync
   (define path
     (build-path
      (force files-path)
      "Examples"))
   (make-directory* path)
   path))

(define-record File
  [path : String]
  [size : UVarint])

(define-record Folder
  [path : String])

(define-enum FilesystemEntry
  [file {file : File}]
  [folder {folder : Folder}])

(define-rpc (get-root-path : String)
  (path->string (force files-path)))

(define-rpc (list-files [at-path root : String] : (Listof FilesystemEntry))
  (for/list ([path (in-directory root (λ (_) #f))])
    (if (directory-exists? path)
        (FilesystemEntry.folder
         (Folder
          #;path (path->string path)))
        (FilesystemEntry.file
         (File
          #;path (path->string path)
          #;size (file-size path))))))

(define-rpc (save [_ content : String]
                  [to path : String])
  (void
   (call-with-output-file path
     #:exists 'replace
     (lambda (out)
       (write-string content out)))))

(define-rpc (read-file [at-path path : String] : String)
  (file->string path))

(define-rpc (create-directory [at-path path : String])
  (make-directory* path))

(define-rpc (delete-directory [at-path path : String])
  (base:delete-directory/files path #:must-exist? #f))

(define-rpc (delete-file [at-path path : String])
  (base:delete-file path))

(define-rpc (make-temp-path : String)
  (define path
    (make-temporary-file
     ".untitled-~a.rkt"
     #;compat-copy-from #f
     #;compat-base-dir (force files-path)))
  (base:delete-file path)
  (path->string path))

(define-rpc (install-examples)
  (define dest-dir (force examples-path))
  (for ([src (in-directory examples-dir (λ (_) #f))]
        #:when (file-exists? src))
    (define dst (build-path dest-dir (file-name-from-path src)))
    (unless (file-exists? dst)
      (copy-file src dst))))
