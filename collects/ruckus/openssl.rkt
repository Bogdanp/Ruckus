#lang racket/base

(require openssl
         racket/runtime-path)

(define-runtime-path cacert.cer
  "cacert.cer")

(ssl-default-verify-sources
 (list cacert.cer))
