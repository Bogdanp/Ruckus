#lang racket/base

(require (prefix-in fmt: fmt)
         noise/backend
         noise/serde)

(define-rpc (format-program [_ src : String] : String)
  (fmt:program-format
   #:formatter-map fmt:standard-formatter-map
   #:max-blank-lines 1
   #:width 79
   src))
