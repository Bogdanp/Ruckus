# Test ExecutionStepper

## Summary

`ExecutionStepper` has 0% test coverage (65 executable lines). It manages an
`AsyncThrowingStream` of `ExecutionStep` values driven by backend callbacks.
Since the Racket backend runs in-process, `ExecutionStepper` can be tested
end-to-end by executing a real script and consuming the step stream.

## Affected Code

### `Ruckus/Models/ExecutionStepper.swift:1-44`

```swift
@MainActor
final class ExecutionStepper {
  static let shared = ExecutionStepper()

  private var signals: [UInt64: AsyncStream<Void>.Continuation] = [:]

  func notify(executionId: UInt64) {
    signals[executionId]?.yield()
  }

  func steps(for executionId: UInt64) -> AsyncThrowingStream<ExecutionStep, Error> {
    let (signalStream, signalContinuation) = AsyncStream<Void>.makeStream()
    signals[executionId] = signalContinuation
    signalContinuation.yield() // trigger the first step

    return AsyncThrowingStream { continuation in
      let task = Task {
        do {
          for await _ in signalStream {
            let step = try await Backend.shared.stepExecution(executionId)
            continuation.yield(step)
            if step.isDone { break }
          }
          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
        await MainActor.run {
          _ = ExecutionStepper.shared.signals.removeValue(forKey: executionId)
        }
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }
}
```

All lines are untested.

## Impact

The stepper is the bridge between Racket backend callbacks and Swift async
iteration. A bug in signal wiring or cleanup would cause executions to hang
or leak continuations.

## Suggested Fix

Add `RuckusTests/Models/ExecutionStepperTests.swift`:

1. **Steps stream yields output and terminates** — save a simple script via
   Backend (e.g. `#lang racket/base\n(displayln "hi")`), call
   `Backend.shared.executeScript(atPath:)` to get an execution ID, install
   the executor-step callback to call `notify`, consume
   `ExecutionStepper.shared.steps(for:)`, verify at least one step has
   non-empty stdout and the final step is `.done`.
2. **Notify for unknown ID is no-op** — call `notify(executionId:)` for an
   ID with no active stream; verify no crash.
3. **Stream cancellation** — start consuming steps, cancel the consuming
   task, verify the stream terminates without hanging.
4. **Multiple concurrent executions** — execute two scripts concurrently,
   consume both step streams, verify each receives its own output without
   cross-contamination.

## Related

- [06-test-execution-service](06-test-execution-service.md) — `ExecutionService.runExecution`
  consumes the stream produced by `ExecutionStepper.steps`.
