# Debounce or coalesce saveSession calls

## Summary

`EditorStore.saveSession()` is called from `selectDocument`, `newDocument`,
`open`, `save`, `close`, and `importFile`. Each invocation spawns a `Task`
that iterates all documents and calls `getRootPath` per document. Multiple
mutations in quick succession (e.g. `close` triggering `newDocument`) each
independently perform the full save work.

## Affected Code

### `Ruckus/Models/EditorStore.swift`

```swift
private func saveSession() {
  guard !isLoading else { return }
  Task { await saveSessionAsync() }
}
```

Every caller fires a new Task unconditionally.

## Suggested Fix

Add a simple coalescing mechanism — for example, a debounce that waits a short
interval before performing the save, cancelling any pending save when a new one
is requested:

```swift
private var saveTask: Task<Void, Never>?

private func saveSession() {
  guard !isLoading else { return }
  saveTask?.cancel()
  saveTask = Task {
    try? await Task.sleep(for: .milliseconds(100))
    guard !Task.isCancelled else { return }
    await saveSessionAsync()
  }
}
```

This is especially helpful once the N+1 `getRootPath` issue (task 21) is also
fixed, since the debounce prevents redundant saves and the batched root path
makes each save cheaper.

## Related

- [21-save-session-n-plus-1.md](21-save-session-n-plus-1.md)
