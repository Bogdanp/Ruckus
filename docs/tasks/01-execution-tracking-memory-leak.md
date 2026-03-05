# Memory Leak in Execution Tracking

## Summary

`AppDelegate.executions` is a static `[UInt64: EditorDocument]` dictionary that
holds **strong references** to documents for the duration of their execution.
If execution terminates abnormally — e.g. the backend crashes, the Noise
connection drops, or `stepExecution` throws an unrecoverable error before the
cleanup path runs — the entry is never removed and the document stays in memory
indefinitely.

## Affected Code

### `AppDelegate.swift:4`

```swift
private static var executions: [UInt64: EditorDocument] = [:]
```

Documents are inserted at `EditorStore.swift:109`:

```swift
AppDelegate.register(doc, executionId: id)
```

They are removed in two places inside `AppDelegate.step(_:)` (lines 61 and 68):

```swift
executions.removeValue(forKey: executionId)
```

### The gap

Removal only happens inside the `Task` launched by `step(_:)`. If
`Backend.shared.stepExecution(executionId)` hangs forever, throws before the
removal path, or the Task itself is dropped, the entry persists.

There is also no periodic sweep or app-lifecycle hook that clears stale entries.

## Reproduction Scenario

1. Open a document and run a script.
2. Kill the Racket backend process externally (or simulate a Noise protocol
   error) while the script is mid-execution.
3. The `step` Task's `catch` block should fire and clean up — but if the
   `stepExecution` call itself never returns (hangs), neither the `do` nor the
   `catch` block executes.
4. The document and its attributed-string output buffer remain in memory
   forever.

## Impact

- Leaked `EditorDocument` objects hold an `NSAttributedString` output buffer
  that can grow large.
- The leaked entry keeps the `executionId` "occupied" — if the backend reuses
  IDs, the stale entry could shadow a new execution.
- Over time, repeated failures accumulate leaked documents with no way to
  reclaim them short of restarting the app.

## Suggested Fix

### Option A: Weak references

Store a weak wrapper instead of a strong reference:

```swift
private static var executions: [UInt64: Weak<EditorDocument>] = [:]

private struct Weak<T: AnyObject> {
    weak var value: T?
}
```

When the document is deallocated (e.g. closed by the user), the weak reference
nils out. `step(_:)` already guards on `guard let doc = executions[...]`, so it
would simply no-op.

### Option B: Periodic sweep

Add an app-lifecycle observer (e.g. `sceneDidBecomeActive`) that iterates
`executions` and removes entries whose document is no longer in
`EditorStore.documents`.

### Option C: Move ownership into `EditorStore`

Instead of a separate static dictionary, let `EditorStore` own the mapping.
Since `EditorStore` already manages document lifecycle and calls
`AppDelegate.unregister` on close, consolidating the mapping there keeps
ownership in one place. The callback from `AppDelegate` would route through
`EditorStore` instead.

## Related

- Task 02 (double-execution) — both stem from execution lifecycle management.
