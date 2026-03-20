# Improve EditorStore test coverage

## Summary

`EditorStore` is at 43% line coverage (167/388 lines). The existing tests in
`EditorStoreTests.swift` thoroughly cover tab management (`reorderDocuments`,
`close`, `selectDocument`, `newDocument`, `hasOpenDocuments`,
`closeDocuments`) but many methods and computed properties remain untested.
Since the Racket backend runs in-process, Backend-dependent methods like
`open`, `save`, `execute`, `revert`, `formatActiveDocument`, `importFile`,
and `restoreSession` are all testable in unit tests.

## Affected Code

### `Ruckus/Models/EditorStore.swift:29-33`

```swift
var hasActiveDocument: Bool { activeDocument != nil }
var canRevert: Bool { activeDocument?.canRevert ?? false }
var canExecute: Bool { activeDocument.map { !$0.isEvaluating } ?? false }
var isExecuting: Bool { activeDocument?.isEvaluating ?? false }
var hasOutput: Bool { activeDocument?.hasOutput ?? false }
```

These computed properties are never tested directly. `canExecute` is
partially covered (true/false when evaluating) but `canRevert`,
`isExecuting`, and `hasOutput` are not.

### `Ruckus/Models/EditorStore.swift:64-76`

```swift
func open(path: String) async throws {
  if let existing = documents.first(where: { $0.path == path }) {
    activeDocumentID = existing.id
    saveSession()
    return
  }
  let content = try await Backend.shared.readFile(atPath: path)
  let name = (path as NSString).lastPathComponent
  let doc = EditorDocument(title: name, path: path, code: content)
  documents.append(doc)
  activeDocumentID = doc.id
  saveSession()
}
```

`open` reads a file via Backend — untested but fully testable.

### `Ruckus/Models/EditorStore.swift:78-96`

```swift
func save(_ doc: EditorDocument) async throws { ... }
```

`save` writes via Backend, sets `isDirty = false`, updates
`ScriptManifest` — untested.

### `Ruckus/Models/EditorStore.swift:128-164`

```swift
func execute() async { ... }
```

Full execution lifecycle — saves, calls Backend to execute, registers with
`ExecutionRegistry`, runs via `ExecutionService` — untested.

### `Ruckus/Models/EditorStore.swift:200-208`

```swift
func formatActiveDocument() async { ... }
```

Calls `Backend.shared.formatProgram` — untested.

### `Ruckus/Models/EditorStore.swift:210-218`

```swift
func revert() async { ... }
```

Calls `Backend.shared.readFile` to reload from disk — untested.

### `Ruckus/Models/EditorStore.swift:98-126`

```swift
func close(_ doc: EditorDocument) {
  if let id = doc.executionId {
    ExecutionService.shared.finishExecution(executionId: id, doc: doc, result: .stopped)
    Task {
      do {
        try await Backend.shared.stopExecution(id)
      } catch { ... }
    }
  }
  // ... tab selection logic (tested) ...
}
```

The branch where `doc.executionId != nil` is never exercised.

## Impact

Without these tests, regressions in file open/save, execution lifecycle,
formatting, and revert could go undetected.

## Suggested Fix

Add the following tests to `RuckusTests/Models/EditorStoreTests.swift`:

### Computed properties

1. **`hasActiveDocument`** — true after `newDocument`, false on a fresh store.
2. **`canRevert`** — false for doc without a path, true for doc with path
   and `isDirty == true`.
3. **`isExecuting` / `hasOutput`** — set `isEvaluating` and output on the
   active doc, verify the store properties reflect it.

### Backend-dependent methods

4. **`open`** — save a file via Backend, then call `store.open(path:)`,
   verify the document content matches and it becomes active. Call open
   again with the same path and verify it reuses the existing document.
5. **`save`** — create a new untitled doc, save it, verify `isDirty` is
   false and `doc.path` is set. Read the file back via Backend to confirm.
6. **`execute`** — save a simple `#lang racket/base` script, call
   `execute()`, await completion, verify the doc has output and
   `isEvaluating` returns to false.
7. **`formatActiveDocument`** — set doc code to poorly-formatted Racket,
   call format, verify the code is updated.
8. **`revert`** — save a doc, modify `doc.code`, call `revert()`, verify
   the code matches the saved version.

### Close while executing

9. **Close while executing** — start an execution, close the doc mid-run,
   verify `doc.isEvaluating` is false and `doc.executionId` is nil.

### didSet fallback

10. **`didSet` fallback on reassignment** — call `reorderDocuments` with a
    subset of IDs that excludes the active doc, verify `activeDocumentID`
    falls back to the last remaining document.

## Related

- [06-test-execution-service](06-test-execution-service.md) — tests the
  `finishExecution` method called during close-while-executing.
