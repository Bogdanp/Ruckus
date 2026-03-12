# Extract execution lifecycle from AppDelegate

## Summary

The execution lifecycle is split across `EditorStore`, `AppDelegate`,
`ExecutionRegistry`, and `ExecutionStepper`. The current flow works, but it
depends on non-obvious sequencing and duplicated cleanup logic spread across
UI bootstrap code and model code.

`AppDelegate` is currently doing much more than application setup: it steps
executions, decodes output, updates documents, persists widget cache, fetches
completions, unregisters executions, and removes temp files. That makes the
execution path harder to reason about and much harder to test in isolation.

## Affected Code

### `Ruckus/AppDelegate.swift:11-22`

```swift
_ = Backend.shared.installCallback(onExecutorStep: { executionId in
  Task { @MainActor in
    ExecutionStepper.shared.notify(executionId: executionId)
  }
})
Task {
  do {
    try await Backend.shared.markOnExecutorStepInstalled()
  } catch {
    Logger.backend.error("\(#function): failed to mark executor step installed: \(error)")
  }
}
```

This setup belongs in application bootstrap, but it is coupled directly to the
rest of the execution implementation via global singletons.

### `Ruckus/AppDelegate.swift:62-100`

```swift
static func runExecution(_ executionId: UInt64) {
  let registry = ExecutionRegistry.shared
  guard let doc = registry.document(for: executionId) else { return }
  Task {
    do {
      for try await step in ExecutionStepper.shared.steps(for: executionId) {
        registry.withBuffers(for: executionId) { stdout, stderr in
          // decode and append output
        }
      }
      doc.isEvaluating = false
      doc.executionId = nil
      await saveWidgetCache(executionId: executionId, doc: doc)
      fetchCompletions(executionId: executionId, doc: doc)
      registry.unregister(executionId: executionId)
      cleanupTempFile(doc)
    } catch {
      doc.appendOutput(error.localizedDescription + "\n", stream: .stderr)
      doc.isEvaluating = false
      doc.executionId = nil
      registry.unregister(executionId: executionId)
      cleanupTempFile(doc)
    }
  }
}
```

This is application business logic, not app delegate logic. Success and error
paths also duplicate state reset and cleanup.

### `Ruckus/Models/EditorStore.swift:127-134`

```swift
let id = try await Backend.shared.executeScript(atPath: path)
doc.executionId = id
ExecutionRegistry.shared.register(doc, executionId: id)
AppDelegate.runExecution(id)
```

The store delegates core execution control to `AppDelegate`, which is the
wrong ownership direction.

## Impact

The execution path has hidden invariants and duplicated cleanup. Any change to
stepping, output decoding, completion fetching, widget updates, or temp-file
handling requires edits in multiple places. That increases regression risk and
makes the behavior difficult to unit test.

## Suggested Fix

Introduce a dedicated `ExecutionService` or `ExecutionCoordinator` under
`Ruckus/Models/` or a new `Ruckus/Execution/` area. That service should own:

- starting a run
- stepping the backend stream
- decoding stdout and stderr
- finalizing document state
- reporting explicit terminal results
- side effects like widget cache refresh and symbol completion fetch

`AppDelegate` should only install the backend callback and hand notifications
to the service. `EditorStore` should depend on the service rather than calling
back into `AppDelegate`.

The service should also centralize common cleanup in one `finishExecution(...)`
path instead of duplicating it across success and error branches.

## Related

- [02-execution-terminal-state.md](02-execution-terminal-state.md)
