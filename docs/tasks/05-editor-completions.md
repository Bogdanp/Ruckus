# Add code completions from the Racket namespace

## Summary

After evaluating code, the Racket core knows which bindings are in scope in
the module's namespace. This information should be exposed to Swift so the
editor can offer completions (e.g., function names, imported identifiers).
Currently no completion data flows from the core to the editor.

## Affected Code

### `ruckus-core/executor.rkt:51-63`

```racket
(define (evaluate in)
  (define document-id (string->symbol (format "~a" (object-name in))))
  (parameterize ([current-module-declare-name (make-resolved-module-path document-id)]
                 [current-module-name-resolver (make-collects-resolver)]
                 [current-namespace (make-base-empty-namespace)])
    (eval
     (check-module-form
      (with-module-reading-parameterization
        (lambda ()
          (read-syntax #f in)))
      #;expected-module-sym 'ignored
      #;source-v #f))
    (dynamic-require `',document-id 0)))
```

After `dynamic-require`, the namespace contains all bindings exported by the
module. This information is discarded — nothing captures or exposes it.

## Impact

The editor has no awareness of what identifiers are available after running a
script, so it cannot offer autocompletion suggestions.

## Suggested Fix

### 1. Capture namespace bindings in the core

After evaluation, extract the namespace's bound identifiers and store them
per execution. Add a new RPC to retrieve them:

```racket
(define (evaluate in)
  (define document-id ...)
  (define ns (make-base-empty-namespace))
  (parameterize ([current-module-declare-name (make-resolved-module-path document-id)]
                 [current-module-name-resolver (make-collects-resolver)]
                 [current-namespace ns])
    (eval ...)
    (dynamic-require `',document-id 0))
  ;; Collect exported names from the module's namespace.
  (define names
    (parameterize ([current-namespace ns])
      (namespace-mapped-symbols)))
  names)
```

Store the result in the `execution` struct and expose it via a new RPC:

```racket
(define-rpc (execution-completions [_ id : UVarint] : (Listof String))
  (completions the-executor id))
```

### 2. Wire it up on the Swift side

After an execution completes (in `AppDelegate.step` when `isDone`), call
the new RPC and pass the list of symbols to the editor document so the
`EditorView` can use them for completions.

### 3. Editor integration

Feed the symbol list into Runestone's completion provider or a custom
popover triggered on partial input.

## Related

- None
