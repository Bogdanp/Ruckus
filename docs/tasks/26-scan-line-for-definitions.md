# Scan edited lines for new definitions to augment completions

## Summary

When a user types a new definition (e.g. `(define foo ...)`, `(let ([bar ...`)
and moves to the next line, the newly defined identifier isn't available for
completion until the script is re-evaluated. This is frustrating because the
most common completion target is the thing you just defined.

We should add a backend RPC that extracts bound identifiers from a line of
Racket source, and call it from the Swift side whenever a newline is inserted.
The extracted names are merged into the completion list immediately, bridging
the gap until the next full evaluation refreshes `doc.completions`.

## Affected Code

### `ruckus-core/executor.rkt:174-178`

```racket
(define-rpc (get-execution-symbols [_ id : UVarint] : (Listof String))
  (map symbol->string (symbols the-executor id)))

(define-rpc (get-racket-base-symbols : (Listof String))
  (map symbol->string (namespace-mapped-symbols (module->namespace 'racket/base))))
```

These are the only two sources of completion symbols today. Neither reacts to
edits — they only reflect evaluated state.

### `Ruckus/Views/ContentView.swift:33`

```swift
completions: doc.completions.isEmpty ? store.baseCompletions : doc.completions
```

Completions are passed as a flat list from the store. There is no mechanism to
inject locally-scanned identifiers.

### `Ruckus/Views/Editor/CompletionController.swift:6`

```swift
var allCompletions: [String] = []
```

Single flat array; no distinction between evaluated symbols and locally-scanned
ones.

## Impact

After typing `(define my-helper ...)` and pressing return, the user has to
evaluate the file before `my-helper` appears in completions. For iterative
coding this creates a noticeable lag in the feedback loop.

## Suggested Fix

### 1. New Racket RPC: `scan-line-definitions`

Add a lightweight RPC that parses a single line (or a small string) and returns
any identifiers introduced by binding forms:

```racket
(define-rpc (scan-line-definitions [line : String] : (Listof String))
  ;; Match forms like (define id ...), (define (id ...) ...),
  ;; (define-values (id ...) ...), (let ([id ...] ...) ...),
  ;; (lambda (id ...) ...), (let-values ...), (struct id ...), etc.
  ;; Use read + pattern match on the leading form, not regex.
  ...)
```

This should handle at least: `define`, `define/contract`, `define-values`,
`define-struct`, `struct`, `let`, `let*`, `letrec`, `let-values`, `lambda`,
`λ`.

### 2. Swift: call the RPC on newline insertion

In `CodeEditingView.Coordinator.textView(_:shouldChangeTextIn:replacementText:)`,
when the replacement text is `"\n"`, extract the text of the line being left
and call the new RPC. Merge results into a local set of "pending" identifiers
on the document or completion controller.

### 3. Merge pending identifiers into completions

Either:
- Add a `pendingCompletions: Set<String>` to `CompletionController` and union
  it with `allCompletions` when filtering, or
- Append scanned identifiers directly to `doc.completions` (they'll be
  replaced on the next evaluation anyway).

The second option is simpler; the first is cleaner if we want to visually
distinguish unevaluated completions later.

### 4. Clear pending completions on evaluation

When `ExecutionService.fetchCompletions()` returns fresh symbols, any
locally-scanned identifiers should be discarded since the evaluated set is
now authoritative.

## Related

- Task 08 (inline evaluation) — inline eval would also benefit from
  incremental completion updates.
