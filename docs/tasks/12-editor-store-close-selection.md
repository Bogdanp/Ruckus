# Test EditorStore.close edge cases

## Summary

`EditorStore.close(_:)` has a selection algorithm that picks the next or
previous tab when closing the active document. The existing tests cover
the basic cases (close first/middle/last tab), but the `documents.didSet`
fallback path — where `activeDocumentID` points to a removed document —
is only tested indirectly through `reorderDocumentsExcludingActive`. There
is no test for closing a document that is already not in the `documents`
array (a no-op path), and the `close` method's execution-stopping branch
is only tested with a mock execution ID, not through the full flow.

## Affected Code

### `Models/EditorStore.swift:98-126`

```swift
func close(_ doc: EditorDocument) {
    if let id = doc.executionId {
        ExecutionService.shared.finishExecution(executionId: id, doc: doc, result: .stopped)
        Task {
            do {
                try await Backend.shared.stopExecution(id)
            } catch {
                Logger.editor.warning("\(#function): stop execution failed: \(error)")
            }
        }
    }
    if activeDocumentID == doc.id {
        if let idx = documents.firstIndex(where: { $0.id == doc.id }) {
            let nextIndex = documents.index(after: idx)
            if nextIndex < documents.endIndex {
                activeDocumentID = documents[nextIndex].id
            } else if idx > documents.startIndex {
                activeDocumentID = documents[documents.index(before: idx)].id
            } else {
                activeDocumentID = nil
            }
        }
    }
    documents.removeAll { $0.id == doc.id }
    if documents.isEmpty {
        newDocument()
    }
    saveSession()
}
```

## Impact

The selection logic is correct today but regressions could cause the
editor to show no active tab or the wrong tab after a close.

## Suggested Fix

Add tests for:

1. Closing the **only** tab with two documents (middle tab) leaves the
   other document selected.
2. Closing a **non-existent** document (already removed) is a safe no-op.
3. Close all documents one by one and verify an Untitled document is
   always created when the list empties.

## Related

- None
