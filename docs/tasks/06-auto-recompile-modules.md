# Auto-recompile modules on run

## Summary

When a user runs a script that `require`s other modules (e.g. files in
the same directory, or installed packages), those modules are loaded
from source every time. Racket's `-y` / `--make` flag installs a
compilation manager that automatically compiles modules to `.zo` files
and recompiles them when source files change. This makes subsequent
runs significantly faster since compiled bytecode is loaded instead of
re-parsing source.

Ruckus should enable this behavior so that required modules are
automatically compiled and cached.

## Affected Code

### `ruckus-core/executor.rkt:59-81`

```racket
(define (evaluate in)
  (define-values (document-dir document-name _is-dir?)
    (split-path (format "~a" (object-name in))))
  (define document-id
    (string->symbol (path->string document-name)))
  (define document-spec `',document-id)
  (parameterize ([current-module-declare-name (make-resolved-module-path document-id)]
                 [current-module-name-resolver (make-collects-resolver)]
                 [current-namespace (make-base-empty-namespace)]
                 [current-directory document-dir])
    (namespace-require 'ruckus/openssl)
    (eval
     (check-module-form
      (with-module-reading-parameterization
        (lambda ()
          (read-syntax #f in)))
      #;expected-module-sym 'ignored
      #;source-v #f))
    (let/ec exit
      (parameterize ([current-print pretty-print*]
                     [exit-handler exit])
        (namespace-require document-spec)))
    (namespace-mapped-symbols (module->namespace document-spec))))
```

The `evaluate` function creates a fresh namespace and loads the script.
It does not install a compilation manager, so all `require`d modules
are loaded from source on every run.

## Impact

Scripts that require other local modules or packages are slower than
necessary on repeated runs, because dependencies are re-parsed from
source each time instead of loading cached `.zo` bytecode.

## Suggested Fix

Install `make-compilation-manager-load/use-compiled-handler` from
`compiler/cm` before evaluating the script. This is equivalent to
what `racket -y` does.

```racket
(require compiler/cm)

(define (evaluate in)
  ...
  (parameterize ([current-module-declare-name ...]
                 [current-module-name-resolver (make-collects-resolver)]
                 [current-namespace (make-base-empty-namespace)]
                 [current-directory document-dir]
                 [current-load/use-compiled
                  (make-compilation-manager-load/use-compiled-handler)])
    ...))
```

### Considerations

- The compilation manager writes `.zo` files into `compiled/`
  subdirectories next to the source files. For user scripts in the
  app's sandbox, this is fine. For bundled collects/packages (which
  are read-only in the app bundle), the compilation manager will
  skip recompilation since those already have `.zo` files.

- Per the docs: "Do not install the result of
  `make-compilation-manager-load/use-compiled-handler` when the
  current namespace contains already-loaded versions of modules that
  may need to be recompiled." The `evaluate` function already creates
  a fresh namespace via `make-base-empty-namespace`, so this is safe.

- The handler checks file timestamps and SHA-1 hashes in `.dep` files
  to decide whether to recompile. This means edits to required files
  trigger automatic recompilation on the next run.

## Related

- `ruckus-core/resolver.rkt` — custom module name resolver; should
  work with the compilation manager since it converts `(lib ...)` paths
  to `(file ...)` paths
