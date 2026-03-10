# Move AppDelegate Static Dictionaries to a @MainActor-Isolated Type

## Summary

`AppDelegate` uses two static dictionaries — `executions` and `outputBuffers`
— to track in-flight script executions. These are plain `[UInt64: ...]`
dictionaries with no explicit isolation. They are currently safe because all
access runs on `@MainActor` (via `Task { @MainActor in ... }` in the callback
and `@MainActor` on `EditorStore`), but this is implicit and fragile. Any
future refactoring that moves work off the main actor would silently introduce
data races.

## Affected Code

### `AppDelegate.swift:6-7`

```swift
private static var executions: [UInt64: Weak<EditorDocument>] = [:]
private static var outputBuffers: [UInt64: (stdout: OutputBuffer, stderr: OutputBuffer)] = [:]
```

These are static stored properties on a non-isolated class. The compiler does
not enforce that all access happens on `@MainActor`.

### `AppDelegate.swift:9-17`

```swift
static func register(_ doc: EditorDocument, executionId: UInt64) {
  executions[executionId] = Weak(value: doc)
  outputBuffers[executionId] = (stdout: OutputBuffer(), stderr: OutputBuffer())
}

static func unregister(executionId: UInt64) {
  executions.removeValue(forKey: executionId)
  outputBuffers.removeValue(forKey: executionId)
}
```

`register` is called from `EditorStore.execute()` (`@MainActor`), and
`unregister` from `EditorStore.close()` (`@MainActor`), so this works today.
But the functions themselves are not annotated.

### `AppDelegate.swift:74-123`

`step()` reads and mutates both dictionaries. It is called from a
`Task { @MainActor in }` block, so it runs on the main actor — but the
function signature doesn't declare this.

## Impact

No bug today. The risk is that a future change (e.g. moving step-polling to a
background task for performance) would introduce a data race that the compiler
cannot catch because the dictionaries are just static vars.

## Suggested Fix

Extract execution tracking into a dedicated `@MainActor` type:

```swift
@MainActor
final class ExecutionRegistry {
  static let shared = ExecutionRegistry()

  private var executions: [UInt64: Weak<EditorDocument>] = [:]
  private var outputBuffers: [UInt64: (stdout: OutputBuffer, stderr: OutputBuffer)] = [:]

  func register(_ doc: EditorDocument, executionId: UInt64) { ... }
  func unregister(executionId: UInt64) { ... }
  func document(for executionId: UInt64) -> EditorDocument? { ... }
  func buffers(for executionId: UInt64) -> (stdout: OutputBuffer, stderr: OutputBuffer)? { ... }
}
```

This makes isolation explicit and compiler-enforced. It also removes the need
for `Weak.swift` if the registry is moved into `EditorStore` (which already
owns the documents).

## Related

- Task 06 (eliminate Weak.swift)
