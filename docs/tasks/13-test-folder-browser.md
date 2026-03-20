# Test FolderBrowser state management

## Summary

`FolderBrowser` has 0% test coverage (521 executable lines). While most
of the file is SwiftUI view composition, several private methods contain
testable logic: navigation title computation, folder creation (whitespace
trimming, empty-name guard, path building), and entry deletion (state
update, removal by ID). Since the Racket backend runs in-process, the
Backend-dependent methods (`loadEntries`, `createFolder`, `deleteEntry`)
are testable end-to-end.

## Affected Code

### `Ruckus/Views/FolderBrowser.swift:166-171`

```swift
private var navigationTitle: String {
  if currentDirectory == rootPath {
    return rootTitle
  }
  return (currentDirectory as NSString).lastPathComponent
}
```

### `Ruckus/Views/FolderBrowser.swift:192-202`

```swift
private func createFolder() async {
  let name = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
  guard !name.isEmpty else { return }
  let path = currentDirectory.appendingPathComponent(name)
  // ...Backend call...
}
```

### `Ruckus/Views/FolderBrowser.swift:204-220`

```swift
private func deleteEntry(_ entry: BrowserEntry) async {
  // ...dispatches to deleteFile or deleteDirectory based on kind...
  if case .loaded(var entries) = state {
    entries.removeAll { $0.id == entry.id }
    state = .loaded(entries)
  }
  onDelete?(entry)
}
```

## Impact

Regressions in folder creation or deletion could corrupt the file
browser or leave orphaned files.

## Suggested Fix

Extract the pure logic into testable internal methods or a companion
type. The navigation title and create-folder validation are simple
enough to extract. For end-to-end tests, use Backend directly.

Add `RuckusTests/Views/FolderBrowserTests.swift` with:

1. **Navigation title shows rootTitle at root** — when `currentDirectory
   == rootPath`, returns the configured `rootTitle`.
2. **Navigation title shows last component in subdirectory** — when
   navigated into a subfolder, returns the folder name.
3. **Create folder trims whitespace** — `"  my-folder  "` → creates
   `"my-folder"` at the correct path.
4. **Create folder rejects empty name** — `"   "` → no-op.
5. **Delete file via Backend** — create a file, delete it through
   `deleteEntry`, verify it's removed from the loaded state.
6. **Delete folder via Backend** — create a folder, delete it, verify
   removal.
7. **Delete calls onDelete callback** — verify the callback fires with
   the correct entry.

## Related

- [12-test-save-browser-validation](12-test-save-browser-validation.md) —
  `SaveBrowserSheet` uses `FolderBrowser` as its container.
