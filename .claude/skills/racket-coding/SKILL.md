---
description: |
  Racket coding conventions. Use when writing or modifying Racket (.rkt) files.
user-invocable: false
---

# Style

- When a procedure has many positional arguments, you can use symbol
  comments as a poor man's keywords. For example, instead of `(File p
  s)` you can write `(File #;path p #;size s)`.
- Avoid rightward shift -- when possible, prefer local `define`s
  instead of `let` or similar. Sometimes a `let` is intentional in
  order to shadow definitions.

# Validation

After changing a Racket file, perform the following steps to validate
the change:

1. **Lint**: `./bin/pbraco review <path/to/file.rkt>` -- fix any linting
   issues, but note that the linter may produce false-positives. When in
   doubt, ask the user.
2. **Build**: `make` -- fix any build issues.
3. **Test**: `./bin/pbraco test <path/to/file.rkt>` -- fix any test
   failures.
