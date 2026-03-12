# Batch getRootPath in saveSessionAsync

## Summary

`EditorStore.saveSessionAsync` calls `relativePath(for:)` once per open
document, and each call awaits `Backend.shared.getRootPath()`. For N open
documents this makes N+1 round-trips to the backend (N in the loop + 1 for
the active document). The root path does not change mid-loop.

## Affected Code

### `Ruckus/Models/EditorStore.swift`

```swift
private func saveSessionAsync() async {
  var relativePaths = [String]()
  for doc in documents {
    if let rel = await relativePath(for: doc) {
      relativePaths.append(rel)
    }
  }
  // ...
  if let doc = activeDocument {
    activeRelative = await relativePath(for: doc)
  }
}
```

`relativePath(for:)` calls `Backend.shared.getRootPath()` every time.

## Suggested Fix

Fetch the root path once at the top of `saveSessionAsync` and pass it through
(or use a local helper) so the loop does pure string work with no async calls.

```swift
private func saveSessionAsync() async {
  guard let root = try? await Backend.shared.getRootPath() else { return }
  var relativePaths = [String]()
  for doc in documents {
    guard let path = doc.path, path.hasPrefix(root) else { continue }
    relativePaths.append(Self.relativePath(path, relativeTo: root))
  }
  // ...
}
```
