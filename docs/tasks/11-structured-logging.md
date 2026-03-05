# No Structured Logging

## Summary

The app has no logging infrastructure. Errors are either displayed in the
output panel via `appendOutput(..., stream: .stderr)`, silently swallowed with
`try?`, or simply not reported. There are no os_log/Logger calls anywhere in
the codebase. This makes diagnosing production issues, backend communication
failures, and state inconsistencies extremely difficult.

## Current State

### Errors shown to user (via output panel)

- `EditorStore.swift:86` — save failure before execution
- `EditorStore.swift:100` — temp file creation failure
- `EditorStore.swift:112` — `executeScript` RPC failure
- `EditorStore.swift:123` — stop execution failure
- `EditorStore.swift:149` — revert failure
- `AppDelegate.swift:65` — step execution error
- `ContentView.swift:70` — save failure in Save As flow

### Errors silently swallowed

- `AppDelegate.swift:24` — `try? await markOnExecutorStepInstalled()`
- `AppDelegate.swift:33` — `try? await deleteFile(atPath:)`
- `ContentView.swift:57` — `try? await store.open(path:)`
- `ContentView.swift:190-192` — share temp file creation
- `EditorStore.swift:68` — `try? await stopExecution()` on close
- `EditorStore.swift:130` — `try? String(contentsOf:)` in import
- `EditorStore.swift:134` — `try? await save()` in import
- `EditorStore.swift:198` — `try? await deleteFile()` in cleanup

### Events with no logging at all

- Backend initialization and connection
- Execution lifecycle (start, step, completion)
- Session save/restore
- File open/close
- Document state transitions

## Impact

- **Can't diagnose user-reported bugs.** If a user says "my file didn't save,"
  there's no log trail to determine what happened.
- **Silent `try?` swallows root causes.** The `markOnExecutorStepInstalled`
  failure (line 24) is particularly concerning — if this fails, no execution
  callbacks arrive, and the app silently stops working.
- **No performance visibility.** Backend RPC call durations, Racket execution
  times, and memory usage are invisible.
- **No crash context.** If the app crashes, there's no breadcrumb trail in the
  device console.

## Suggested Fix

### 1. Add a Logger

```swift
import os

extension Logger {
    static let backend = Logger(subsystem: "com.ruckus.app", category: "backend")
    static let editor = Logger(subsystem: "com.ruckus.app", category: "editor")
    static let session = Logger(subsystem: "com.ruckus.app", category: "session")
}
```

### 2. Log at key lifecycle points

**Backend communication:**
```swift
// AppDelegate.swift — callback installation
Logger.backend.info("Installing executor step callback")
_ = Backend.shared.installCallback(onExecutorStep: { ... })

// On failure
Logger.backend.error("markOnExecutorStepInstalled failed: \(error)")
```

**Execution lifecycle:**
```swift
Logger.editor.info("Starting execution for document \(doc.title)")
Logger.editor.info("Execution \(id) step received: done=\(isDone)")
Logger.editor.error("Execution \(id) step failed: \(error)")
```

**Session persistence:**
```swift
Logger.session.info("Saving session: \(relativePaths.count) documents")
Logger.session.info("Restoring session: \(relativePaths.count) paths")
Logger.session.warning("Failed to restore document at \(fullPath): \(error)")
```

### 3. Replace silent `try?` with logged errors

```swift
// Before
try? await Backend.shared.markOnExecutorStepInstalled()

// After
do {
    try await Backend.shared.markOnExecutorStepInstalled()
} catch {
    Logger.backend.error("Failed to mark executor step installed: \(error)")
}
```

Not every `try?` needs to become a full `do/catch` — for cleanup operations
like `deleteFile`, a one-liner is fine:

```swift
do { try await Backend.shared.deleteFile(atPath: path) }
catch { Logger.backend.warning("Temp file cleanup failed: \(error)") }
```

### 4. Scope and priorities

Don't add logging everywhere at once. Priority order:

1. **Backend initialization** — silent failures here break the entire app.
2. **Execution lifecycle** — most common user-facing operation.
3. **Session restore** — most common source of "where did my files go?"
4. **File operations** — save/open/import failures.
5. **UI state** — lower priority, only if debugging state inconsistencies.
