# Make execution completion distinguish terminal states

## Summary

Execution completion is currently modeled as "the execution was removed from
`ExecutionRegistry`", not as "the execution reached a terminal outcome". That
conflates successful completion with user-initiated stop, document close, and
error teardown.

This is especially visible in the App Intent flow, which waits on
`awaitCompletion(of:)` and then returns the current output as if the run
finished normally. Closing a document or unregistering an execution early can
therefore surface truncated output as a successful run result.

## Affected Code

### `Ruckus/Models/ExecutionRegistry.swift:14-37`

```swift
func unregister(executionId: UInt64) {
  executions.removeValue(forKey: executionId)
  outputBuffers.removeValue(forKey: executionId)
  if let waiting = completions.removeValue(forKey: executionId) {
    for continuation in waiting { continuation.resume(returning: ()) }
  }
}

func awaitCompletion(of executionId: UInt64) async throws {
  try await withTaskCancellationHandler {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
      if executions[executionId] == nil {
        continuation.resume()
      } else {
        completions[executionId, default: []].append(continuation)
      }
    }
  } onCancel: {
    Task { @MainActor in
      if let waiting = completions.removeValue(forKey: executionId) {
        for continuation in waiting { continuation.resume(throwing: CancellationError()) }
      }
    }
  }
}
```

Waiters resume successfully whenever the registry entry disappears, regardless
of whether the run completed, failed, or was manually stopped.

### `Ruckus/Models/EditorStore.swift:79-89`

```swift
if let id = doc.executionId {
  ExecutionRegistry.shared.unregister(executionId: id)
  Task {
    do {
      try await Backend.shared.stopExecution(id)
    } catch {
      Logger.editor.warning("\(#function): stop execution failed: \(error)")
    }
  }
}
```

Closing a document unregisters first and asks the backend to stop later, so
any waiter sees a normal completion before the stop is even attempted.

### `Ruckus/Intents/ExecuteScriptIntent.swift:27-33`

```swift
await store.execute()
guard let executionId = doc.executionId else {
  throw IntentError.message("Failed to start script execution.")
}
try await ExecutionRegistry.shared.awaitCompletion(of: executionId)
let output = doc.output.string
return .result(value: output)
```

The intent assumes `awaitCompletion` means a successful terminal run.

## Impact

Automation and background integrations can report false success and return
partial output. This is most likely when the user closes a document mid-run,
stops execution, or when teardown happens on an error path that unregisters
the execution before a terminal status is recorded.

## Suggested Fix

Introduce an explicit terminal result model for executions, for example:

```swift
enum ExecutionResult {
  case completed
  case stopped
  case failed(Error)
}
```

Have the execution subsystem record that result before removing the execution
from active storage, and make `awaitCompletion` return the terminal result
instead of `Void`. App Intents and UI callers can then decide whether to
surface stopped runs as errors, cancellations, or partial-output cases.

As a follow-up, add tests covering:

- successful completion
- user stop
- document close during execution
- backend error during stepping

## Related

- [03-execution-service-boundary.md](03-execution-service-boundary.md)
