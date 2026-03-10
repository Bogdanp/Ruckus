# Eliminate Weak.swift by Moving Execution Registry Into EditorStore

## Summary

`Weak.swift` exists solely to wrap `EditorDocument` references in
`AppDelegate.executions` dictionary to avoid retain cycles. If the execution
registry is moved into `EditorStore` (which already owns the documents),
the weak wrapper becomes unnecessary because the store can look up documents
directly from its own `documents` array.

## Affected Code

### `Weak.swift:1-3`

```swift
struct Weak<T: AnyObject> {
  weak var value: T?
}
```

### `AppDelegate.swift:6`

```swift
private static var executions: [UInt64: Weak<EditorDocument>] = [:]
```

Only usage of `Weak` in the entire codebase.

### `AppDelegate.swift:10,75`

```swift
executions[executionId] = Weak(value: doc)
...
guard let doc = executions[executionId]?.value else { return }
```

## Impact

No bug — purely a simplification. `Weak<T>` is a 3-line file that adds a
concept (`Weak`) for a single use site.

## Suggested Fix

If the execution registry moves to `EditorStore` (see task 03), store the
execution ID on the document (already done: `EditorDocument.executionId`)
and look up documents by ID:

```swift
// In EditorStore or a new ExecutionRegistry
func document(for executionId: UInt64) -> EditorDocument? {
  documents.first { $0.executionId == executionId }
}
```

This eliminates the need for `Weak.swift` entirely. The lookup is O(n) on
the documents array, but the array is always tiny (number of open tabs).

Delete `Weak.swift` after migration.

## Related

- Task 03 (move AppDelegate static dicts to isolated type) — this is a
  natural follow-up.
