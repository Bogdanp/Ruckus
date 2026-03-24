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
    "threading-lib"

    ;; Not used by ruckus-core, but included in the distribution:
    "crypto"
    "csv-reading"
    "csv-writing"
    "deta"
    "http-easy"
    "math"
    "memoize"
    "rackcheck"
    "rackunit"
    "threading"))
