#lang racket/base

(require noise/backend
         noise/serde
         racket/file
         racket/promise
         "appdata.rkt")

(provide
 (record-out File)
 (record-out Folder)
 (enum-out FilesystemEntry))

(define files-path
  (delay/sync
   (define path (build-application-path "files"))
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

(define-rpc (list-files [root : String] : (Listof FilesystemEntry))
  (for/list ([path (in-directory root (λ (_) #f))])
    (if (directory-exists? path)
        (FilesystemEntry.folder (Folder path))
        (FilesystemEntry.file
         (File
          #;path (path->string path)
          #;size (file-size path))))))

(define-rpc (save [content : String]
                  [to path : String])
  (void
   (call-with-output-file path
     #:exists 'replace
     (lambda (out)
       (write-string content out)))))

(define-rpc (delete [path : String])
  (delete-file path))
