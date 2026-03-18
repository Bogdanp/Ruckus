---
description: |
  Racket coding conventions. Use when writing or modifying Racket (.rkt) files.
---

# Racket Coding Style

- When a procedure has many positional arguments, you can use symbol
  comments as a poor man's keywords. For example, instead of `(File p
  s)` you can write `(File #;path p #;size s)`.
