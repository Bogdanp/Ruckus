# Test ExecutionService

## Summary

`ExecutionService` has 0% test coverage (135 executable lines). Since the
Racket backend runs in-process, both `runExecution` and `finishExecution`
are fully testable in unit tests. `runExecution` drives the execution
lifecycle by iterating over `ExecutionStepper.steps`, decoding output via
`OutputBuffer`, and appending it to the document. `finishExecution` resets
document state and cleans up the registry.

## Affected Code

### `Ruckus/Models/ExecutionService.swift:9-46`

```swift
func runExecution(_ executionId: UInt64) {
  let registry = ExecutionRegistry.shared
  guard let doc = registry.document(for: executionId) else { return }
  Task {
    var result: ExecutionResult
    do {
      for try await step in ExecutionStepper.shared.steps(for: executionId) {
        registry.withBuffers(for: executionId) { stdout, stderr in
          let stdoutText = stdout.decode(step.output.stdout)
          if !stdoutText.isEmpty {
            doc.appendOutput(stdoutText, stream: .stdout)
          }
          let stderrText = stderr.decode(step.output.stderr)
          if !stderrText.isEmpty {
            doc.appendOutput(stderrText, stream: .stderr)
          }
          if step.isDone {
            let trailingStdout = stdout.flush()
            if !trailingStdout.isEmpty {
              doc.appendOutput(trailingStdout, stream: .stdout)
            }
            let trailingStderr = stderr.flush()
            if !trailingStderr.isEmpty {
              doc.appendOutput(trailingStderr, stream: .stderr)
            }
          }
        }
      }
      result = .completed
      await saveWidgetCache(executionId: executionId, doc: doc)
      fetchCompletions(executionId: executionId, doc: doc)
    } catch {
      doc.appendOutput(error.localizedDescription + "\n", stream: .stderr)
      result = .failed(error)
    }
    finishExecution(executionId: executionId, doc: doc, result: result)
  }
}
```

The full execution loop — untested.

### `Ruckus/Models/ExecutionService.swift:48-53`

```swift
func finishExecution(executionId: UInt64, doc: EditorDocument, result: ExecutionResult) {
  doc.isEvaluating = false
  doc.executionId = nil
  ExecutionRegistry.shared.unregister(executionId: executionId, result: result)
  EditorStore.shared.cleanupTempFile(doc)
}
```

State cleanup — untested.

## Impact

`ExecutionService` is the core orchestrator for script execution. Without
tests, regressions in output decoding, state transitions, or cleanup could
leave documents stuck in evaluating state or lose script output.

## Suggested Fix

Add `RuckusTests/Models/ExecutionServiceTests.swift`:

### finishExecution tests

1. **Clears evaluating state** — create a doc with `isEvaluating = true` and
   a non-nil `executionId`, register it in `ExecutionRegistry`, call
   `finishExecution`, verify `doc.isEvaluating == false` and
   `doc.executionId == nil`.
2. **Unregisters from registry** — after `finishExecution`, verify
   `ExecutionRegistry.shared.document(for:)` returns nil for that ID.
3. **Clears temp file path** — set `doc.tempPath` to a value, call
   `finishExecution`, verify `doc.tempPath` is nil.
4. **Each result variant** — call with `.completed`, `.stopped`, and
   `.failed(someError)` to ensure none crash.

### runExecution end-to-end tests

5. **Successful execution produces output** — save a script like
   `#lang racket/base\n(displayln "hello")` via Backend, call
   `Backend.shared.executeScript(atPath:)` to get an execution ID, register
   the doc in `ExecutionRegistry`, call `runExecution`, await completion via
   `ExecutionRegistry.shared.awaitCompletion(of:)`, verify `doc.output`
   contains "hello" and `doc.isEvaluating` is false.
6. **Stderr output is captured** — execute a script that writes to stderr
   (e.g. `(eprintf "err")`), verify stderr appears in the doc output.
7. **Failed execution records error** — execute a script with a syntax error,
   verify the doc receives error output and result is `.failed`.

## Related

- [04-test-editor-store-coverage](04-test-editor-store-coverage.md) — `EditorStore.execute`
  calls `runExecution`.
- [11-test-execution-stepper](11-test-execution-stepper.md) — `runExecution`
  consumes the stream produced by `ExecutionStepper.steps`.
