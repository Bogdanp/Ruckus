# No Guard Against Double-Execution

## Summary

A user can tap the Run button multiple times in rapid succession. Each tap
calls `EditorStore.execute()`, which overwrites the document's execution state
(`isEvaluating`, `executionId`, `tempPath`) without checking whether an
execution is already in progress. The first execution becomes orphaned — still
running on the backend with no way to stop or track it.

## Affected Code

### `EditorStore.swift:80-116` — `execute()`

```swift
func execute() async {
    guard let doc = activeDocument else { return }
    // ... save logic ...
    doc.output = NSAttributedString()   // wipes output from first run
    doc.isEvaluating = true
    do {
        let id = try await Backend.shared.executeScript(atPath: path)
        doc.executionId = id            // overwrites previous executionId
        AppDelegate.register(doc, executionId: id)
        AppDelegate.step(id)
    } catch { ... }
}
```

There is no `guard !doc.isEvaluating else { return }` at the top.

### `ContentView.swift:153-156` — Run button

```swift
Button {
    Task { await store.execute() }
} label: {
    Label("Run", systemImage: "play.fill")
}
.disabled(store.activeDocument == nil)
```

The button is disabled when there's no document, but **not** when
`isEvaluating == true`. (The toolbar does switch to a Stop button when
evaluating, but there's a window between the tap and when `isEvaluating`
becomes `true` where the Run button is still visible.)

## What Goes Wrong

1. User taps Run. `execute()` starts, saves, calls `executeScript`. Before the
   `await` returns, the button is still enabled (SwiftUI hasn't re-rendered
   yet).
2. User taps Run again. A second `execute()` call starts.
3. Second call sets `doc.output = NSAttributedString()` — wiping output from
   the first run's in-flight steps.
4. Second call sets `doc.executionId = newId` — the old execution ID is lost.
5. `AppDelegate.register(doc, executionId: newId)` adds a new entry but the
   old entry still exists, pointing to the same document.
6. The old execution keeps running on the Racket side with no way to stop it
   (the ID is forgotten).
7. Steps from the old execution still arrive and mutate `doc.output`,
   interleaving with the new execution's output.

## Impact

- Orphaned Racket-side executions consume resources until they complete
  naturally or the app exits.
- Output from both executions is interleaved in the same output panel, making
  it incomprehensible.
- `AppDelegate.executions` accumulates stale entries (connects to Task 01).
- If the user later taps Stop, only the latest execution is stopped.

## Suggested Fix

### Option A: Guard at the top of `execute()`

```swift
func execute() async {
    guard let doc = activeDocument, !doc.isEvaluating else { return }
    // ...
}
```

This is the simplest fix. The second tap is silently ignored.

### Option B: Stop-then-restart

If re-running while executing is desired behavior (like a "restart" action):

```swift
func execute() async {
    guard let doc = activeDocument else { return }
    if let existingId = doc.executionId {
        try? await Backend.shared.stopExecution(existingId)
        AppDelegate.unregister(executionId: existingId)
        cleanupTempFile(doc)
    }
    // proceed with new execution
}
```

### Option C: Disable the Run button properly

In addition to either option above, ensure the button can't be tapped during
the async gap:

```swift
.disabled(store.activeDocument == nil || store.activeDocument?.isEvaluating == true)
```

The toolbar already switches between Run/Stop, but adding this guard defends
against the race window.

## Related

- Task 01 (memory leak) — orphaned executions leave stale entries.
