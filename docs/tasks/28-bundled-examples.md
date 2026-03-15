# Bundled Examples

## Summary

Ship a set of example Racket files (sourced from Jens-Axel Soegaard's
[minischeme examples](https://soegaard.github.io/webracket/minischeme.html),
used with permission) so that new users have something to open on first
launch. The examples should be stored in the `ruckus-core` distribution,
installed into the user's files directory via a new RPC, and the UI should
call that RPC automatically on first run.

## Plan

### 1. Add example files to `ruckus-core/examples/`

Save the example `.rkt` files from the minischeme page under
`ruckus-core/examples/`. Keep filenames descriptive (e.g.
`hello-world.rkt`, `fibonacci.rkt`).

### 2. Create `ruckus-core/example.rkt`

```racket
#lang racket/base
(require racket/runtime-path)

(define-runtime-path examples-dir "examples")

(provide examples-dir)
```

This ensures the `examples/` directory is included in the built
distribution via `define-runtime-path`.

### 3. Add an `install-examples` RPC in `filesystem.rkt`

```racket
(require "example.rkt")

(define-rpc (install-examples)
  (for ([src (in-directory examples-dir (λ (_) #f))]
        #:when (file-exists? src))
    (define dest (build-path (force files-path) (file-name-from-path src)))
    (unless (file-exists? dest)
      (copy-file src dest))))
```

The RPC copies every file from the bundled examples directory into the
user's files root, skipping any that already exist so it doesn't
overwrite user edits.

### 4. Regenerate the Swift backend bindings

Run `make backend` (or equivalent) so `Backend.swift` picks up the new
`installExamples` RPC.

### 5. Call the RPC on first launch in the UI

In the appropriate Swift entry point (likely the file-browser or app-init
code), check a `UserDefaults` flag (e.g. `hasInstalledExamples`) and, if
false, call `Backend.installExamples()` then set the flag.

## Affected Code

### `ruckus-core/filesystem.rkt`

New `install-examples` RPC will be added here, alongside the existing
file-management RPCs.

### `ruckus-core/example.rkt` (new)

Module to declare the runtime path for the bundled examples directory.

### `ruckus-core/examples/` (new)

Directory containing the bundled `.rkt` example files.

### Swift UI layer

A first-run check needs to be added to call `installExamples` on initial
launch.

## Impact

Currently new users see an empty file list on first launch. Bundled
examples give them something to explore immediately, improving the
first-run experience.

## Suggested Fix

See the plan above for concrete implementation steps.

## Related

- Source: https://soegaard.github.io/webracket/minischeme.html (permission
  granted by Jens-Axel Soegaard)
