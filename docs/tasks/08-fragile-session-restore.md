# Fragile Session Restore Path Parsing

## Summary

Session persistence relies on extracting a relative path from an absolute path
by searching for the substring `/files/`. This is brittle: if the app's data
directory structure changes, if a file is saved outside the `files/` directory,
or if the path itself contains `/files/` elsewhere, session restore breaks
silently.

## Affected Code

### `EditorStore.swift:202-205` — `relativePath(for:)`

```swift
private static func relativePath(for absolutePath: String) -> String? {
    guard let range = absolutePath.range(of: "/files/") else { return nil }
    return String(absolutePath[range.upperBound...])
}
```

This function is used in two places:

### `EditorStore.swift:209` — `saveSession()`

```swift
let relativePaths = documents.compactMap { $0.path.flatMap(Self.relativePath) }
UserDefaults.standard.set(relativePaths, forKey: Self.openDocumentPathsKey)
```

### `EditorStore.swift:170-171` — `restoreSession()`

```swift
for relativePath in relativePaths {
    let fullPath = (root as NSString).appendingPathComponent(relativePath)
```

The root path comes from `Backend.shared.getRootPath()`, which returns the
Racket filesystem root (presumably ending in `/files`).

## What Can Go Wrong

### 1. Path contains `/files/` elsewhere

If the app sandbox path happens to contain `/files/` (e.g.
`/var/mobile/.../files/Application/.../files/foo.rkt`), `range(of:)` finds the
**first** occurrence, not the last. The relative path becomes
`Application/.../files/foo.rkt` instead of `foo.rkt`.

### 2. Files saved outside the `files/` directory

If a file is saved to a temp path or another location (e.g. via the
unsanitized filename issue in Task 04), `relativePath(for:)` returns `nil`.
The document is silently excluded from the saved session. On next launch, it
doesn't appear in the tab bar.

### 3. Backend root path changes

If the Racket backend's root path changes between app versions (e.g.
directory renamed from `files` to `documents`), all saved relative paths
become invalid. `restoreSession` tries to read files at non-existent paths,
catches the errors, and falls through to `newDocument()`. All open tabs are
lost.

### 4. Documents without paths are lost

Unsaved documents (where `doc.path == nil`) are filtered out by `compactMap`
and not restored. This is by design for truly new documents, but a document
that was edited and had its path cleared somehow would be silently lost.

## Impact

- Open documents silently disappear from the session after app restart.
- No error message or indication that restoration failed.
- User loses their working context.

## Suggested Fix

### Option A: Store relative paths from the root at save time

Instead of deriving relative paths from absolute paths, compute the relative
path once when the path is set, and store it alongside the absolute path:

```swift
class EditorDocument {
    var path: String?
    var relativePath: String?  // relative to backend root
}
```

In `EditorStore.save(_:)`:

```swift
let root = try await Backend.shared.getRootPath()
doc.relativePath = String(path.dropFirst(root.count + 1))
// or use URL-based relative path computation
```

### Option B: Use `URL.relativePath` or `FilePath`

Convert to `URL` and use proper path arithmetic:

```swift
private static func relativePath(for absolutePath: String, root: String) -> String? {
    let absURL = URL(fileURLWithPath: absolutePath)
    let rootURL = URL(fileURLWithPath: root)
    // Check that absURL is actually under rootURL
    guard absolutePath.hasPrefix(root) else { return nil }
    return String(absolutePath.dropFirst(root.count).drop(while: { $0 == "/" }))
}
```

### Option C: Store absolute paths

If the root path is stable within a single device, just store absolute paths
in UserDefaults. On restore, validate that the files still exist at those
paths. This is simpler and avoids the root-path dependency entirely.

The downside is that if the app container is migrated (rare but possible on
iOS), the absolute paths break. But that's the same failure mode as the
current approach.

## Related

- Task 04 (unsanitized filenames) — files saved outside `/files/` trigger
  this issue.
