#lang racket/base

(require racket/file
         racket/promise)

(provide
 build-application-path)

(define app-id "io.defn.Ruckus")

(define application-data-directory
  (delay/sync
   (define path
     (case (system-type 'os*)
       [(macosx ios)
        (build-path
         (find-system-path 'home-dir)
         "Library"
         "Application Support"
         app-id)]

       [(linux unix)
        (build-path
         (or (getenv "XDG_CONFIG_HOME")
             (expand-user-path "~/.config"))
         app-id)]

       [else
        (error 'current-application-data-directory "not implemented")]))
   (make-directory* path)
   path))

(define (build-application-path . args)
  (apply build-path (force application-data-directory) args))
