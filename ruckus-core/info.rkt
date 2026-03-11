#lang info

(define collection "ruckus")
(define deps
  '("actor-lib"
    "base"
    ["noise-serde-lib" #:version "0.11"]
    "sandbox-lib"
    "struct-define"
    "threading-lib"

    ;; Unused, but distributed:
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
