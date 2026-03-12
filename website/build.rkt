#lang racket/base

(require racket/file
         racket/path
         racket/runtime-path
         xml)

(provide
 build)

(define-runtime-path build-dir "build")
(define-runtime-path images-dir "images")
(define-runtime-path pages-dir "pages")
(define-runtime-path style.css "style.css")

(define (build)
  (delete-directory/files build-dir #:must-exist? #f)
  (make-directory* build-dir)
  (copy-directory/files images-dir (build-path build-dir "images"))
  (copy-file style.css (build-path build-dir "style.css"))
  (for ([p (in-directory pages-dir)]
        #:unless (regexp-match? #rx#"^\\.#" (file-name-from-path p))
        #:when (equal? (path-get-extension p) #".rkt"))
    (define-values (_dir name _is-dir?)
      (split-path p))
    (define target-path
      (build-path build-dir (path-replace-extension name #".html")))
    (define xexpr
      ((dynamic-require `(file ,(path->string p)) 'render)))
    (call-with-output-file target-path
      (lambda (out)
        (displayln "<!DOCTYPE html>" out)
        (parameterize ([current-unescaped-tags html-unescaped-tags])
          (write-xexpr xexpr out))))))

(module+ main
  (build))
