# Add interactive REPL

## Summary

The app can only execute whole scripts. There is no way to evaluate individual
expressions interactively. An interactive REPL (read-eval-print loop) would
let users experiment with expressions, inspect values, and iterate quickly
without running an entire file.

## Affected Code

### `Ruckus/Models/EditorStore.swift:100-136`

```swift
func execute() async {
  // Saves the whole file, then calls Backend.shared.executeScript(atPath:)
  // Output is streamed via ExecutionStepper into doc.output
}
```

Execution is file-based: save to disk, execute the whole file, stream output.

### `ruckus-core/executor.rkt`

The Racket executor creates a thread per script execution and captures
stdout/stderr. There is no mechanism for sending individual expressions to
an already-running namespace.

## Impact

Users cannot interactively explore APIs, test small expressions, or inspect
intermediate values. They must write a full script, run it, and read the
output — a much slower feedback loop than a REPL.

## Suggested Fix

1. **New RPC method `evalExpression`** — add a Racket-side RPC that evaluates
   a single expression string in a given namespace (either fresh or from a
   previously-run script). Return the result as a string (via `~v` or
   `pretty-print`).
2. **REPL UI** — add a new view (sheet or split pane) with a prompt input
   field and scrolling output history. Each expression and its result appear
   as a pair in the history.
3. **Evaluate selection** — see task 08 (inline evaluation) which builds on
   the `evalExpression` RPC to evaluate selected code from the editor.
4. **Namespace persistence** — keep the REPL namespace alive across
   evaluations so that definitions accumulate, matching DrRacket's
   interactions window behavior.
