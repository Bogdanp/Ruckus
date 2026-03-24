#lang info

(define collection "ruckus")
(define deps
  '("actor-lib"
    "base"
    "fmt"
    ["noise-serde-lib" #:version "0.11"]
    "ruckus-openssl"
    "sandbox-lib"
    "struct-define"
    "threading-lib"))
