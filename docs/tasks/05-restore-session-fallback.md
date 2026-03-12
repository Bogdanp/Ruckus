# Ensure session restore always leaves a usable editor

## Summary

`restoreSession()` does not guarantee that the app ends in a usable editor
state. If fetching the backend root path fails during startup, the method logs
an error and returns, but still flips `isLoading` to `false` via `defer`.

That leaves the main UI loaded with no document tabs and no active editor,
which is an awkward partial state for both users and future code.

## Affected Code

### `Ruckus/Models/EditorStore.swift:181-195`

```swift
func restoreSession() async {
  defer { isLoading = false }
  guard let relativePaths = UserDefaults.standard.stringArray(forKey: Self.openDocumentPathsKey),
        !relativePaths.isEmpty else {
    newDocument()
    return
  }
  let activeRelativePath = UserDefaults.standard.string(forKey: Self.activeDocumentPathKey)
  let root: String
  do {
    root = try await Backend.shared.getRootPath()
  } catch {
    Logger.session.error("\(#function): failed to get root path: \(error)")
    return
  }
```

The error path exits without restoring previous docs and without creating a
fallback unsaved document.

### `Ruckus/Views/ContentView.swift:16-39`

```swift
if store.isLoading {
  ProgressView()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
} else {
  VStack(spacing: 0) {
    TabBar(
      documents: store.documents,
      activeDocumentID: store.activeDocumentID,
      onSelect: { store.selectDocument($0) },
      onClose: { store.close($0) },
      onNew: { store.newDocument() }
    )
    if let doc = store.activeDocument {
      CodeEditingView(...)
    }
  }
}
```

The view can render with an empty tab bar and no editor if session restore
falls through this startup error path.

## Impact

Users see an incomplete app shell with no obvious recovery path except manual
interaction. It also creates an unnecessary implicit invariant: callers must
remember that `isLoading == false` does not imply the store is ready.

## Suggested Fix

Make `restoreSession()` guarantee one of these postconditions before it
returns:

- at least one document exists and `activeDocumentID` is set
- the store exposes a distinct bootstrap error state that the UI renders

The simpler fix is to call `newDocument()` when root-path resolution fails. A
cleaner option is to model startup as an enum like `.loading`, `.ready`,
`.failed(message)` and let `ContentView` render a proper recovery UI.

Add tests for:

- no saved session
- saved session restored successfully
- root-path lookup failure with fallback document
- saved paths all missing, resulting in a new document

## Related

- None.
