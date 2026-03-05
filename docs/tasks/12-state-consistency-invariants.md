# State Consistency: Missing Invariants in EditorStore

## Summary

`EditorStore` uses multiple independent `@Observable` properties (`documents`,
`activeDocumentID`, `isLoading`) with no invariant enforcement. It's possible
for `activeDocumentID` to reference a UUID that doesn't exist in the
`documents` array, causing `activeDocument` to return `nil` unexpectedly.
Several UI flows depend on `activeDocument` being non-nil and degrade silently
when it isn't.

## Affected Code

### `EditorStore.swift:9-15` — The core state

```swift
var documents: [EditorDocument] = []
private(set) var activeDocumentID: UUID?

var activeDocument: EditorDocument? {
    guard let id = activeDocumentID else { return nil }
    return documents.first { $0.id == id }
}
```

`activeDocument` is a computed property that does a linear search. If the
document array has been mutated (via `close`, `restoreSession`, or direct
manipulation) without updating `activeDocumentID`, this returns `nil`.

### Invariant violations

**1. `restoreSession` clears then rebuilds:**

```swift
// EditorStore.swift:167-168
documents.removeAll()
activeDocumentID = nil
```

Between `removeAll()` and the re-population loop, if any code path accesses
`activeDocument`, it gets `nil`. This is safe today because `restoreSession`
is `async` and runs on `@MainActor`, so no re-entrant access can occur during
the synchronous section. But it's a latent fragility — adding any `await`
between the clear and repopulate would open a window.

**2. `close` updates `activeDocumentID` conditionally:**

```swift
// EditorStore.swift:70-73
documents.removeAll { $0.id == doc.id }
if activeDocumentID == doc.id {
    activeDocumentID = documents.last?.id
}
```

This is correct, but only because `documents.removeAll` runs synchronously
before the `if` check. If someone refactors this to be async-aware (e.g.
adding an animation), the sequencing could break.

**3. External mutation of `documents`:**

`documents` is `var` (not `private(set)`), so any code with access to the
store can mutate the array directly, potentially removing the active document
without updating `activeDocumentID`.

**4. Linear search on every access:**

`activeDocument` does `documents.first { $0.id == id }` — an O(n) search. For
a small number of tabs this is fine, but it's called from multiple view
`body` properties, meaning it runs on every SwiftUI evaluation. With many
open documents, this adds up.

## Impact

- **Nil `activeDocument` unexpectedly**: If invariants break, the toolbar Run
  button becomes permanently disabled, Save does nothing, and the editor area
  shows blank — all without any error message.
- **State desync**: `activeDocumentID` pointing at a removed document means
  `selectDocument` appears to work (sets the ID) but the UI shows nothing.
- **Fragile refactoring**: Anyone modifying `close()` or `restoreSession()`
  must understand the implicit invariant. There's no compiler or runtime check
  to catch violations.

## Suggested Fix

### Option A: Enforce invariants via encapsulation

Make `documents` `private(set)` and route all mutations through methods that
maintain the invariant:

```swift
private(set) var documents: [EditorDocument] = []
private(set) var activeDocumentID: UUID?

var activeDocument: EditorDocument? {
    guard let id = activeDocumentID else { return nil }
    return documents.first { $0.id == id }
}

private func setActive(_ id: UUID?) {
    if let id, documents.contains(where: { $0.id == id }) {
        activeDocumentID = id
    } else {
        activeDocumentID = documents.last?.id
    }
}
```

Every method that mutates `documents` calls `setActive` afterward to
revalidate.

### Option B: Derive `activeDocumentID` validation

Add a `didSet` observer on `documents` that validates the active ID:

```swift
var documents: [EditorDocument] = [] {
    didSet {
        if let id = activeDocumentID, !documents.contains(where: { $0.id == id }) {
            activeDocumentID = documents.last?.id
        }
    }
}
```

This is simpler but relies on `didSet` firing for all mutation types (it does
for array reassignment but **not** for in-place mutations via subscript on
older Swift versions — though with `@Observable` this is less of a concern).

### Option C: Use an index instead of UUID lookup

Replace UUID-based lookup with an index:

```swift
private(set) var activeDocumentIndex: Int?

var activeDocument: EditorDocument? {
    guard let index = activeDocumentIndex,
          documents.indices.contains(index) else { return nil }
    return documents[index]
}
```

This makes the O(1) but introduces its own invariant (index must be valid
after insertions/deletions). Slightly more complex to maintain than UUID-based,
but eliminates the linear search.

### Recommendation

Option A is the safest. Making `documents` `private(set)` and routing all
mutations through methods that maintain the active-document invariant prevents
accidental breakage during future refactoring.
