# Running an untitled document silently overwrites Untitled.rkt

## Summary

When the user runs an untitled, dirty document, `execute()` calls `save()`
which constructs a path from the document's title — `Untitled.rkt` — and
writes it to the app's root directory. If a file named `Untitled.rkt` already
exists there, it is silently overwritten. The user is never prompted to choose
a filename or confirm the save.

## Affected Code

### `EditorStore.swift:58-76`

```swift
func save(_ doc: EditorDocument) async throws {
    let path: String
    if let existing = doc.path {
      path = existing
    } else {
      let root = try await Backend.shared.getRootPath()
      let filename = doc.title.hasSuffix(".rkt") ? doc.title : doc.title + ".rkt"
      guard !filename.contains("/"), !filename.contains("..") else {
        throw SaveError.invalidFilename
      }
      path = (root as NSString).appendingPathComponent(filename)
      doc.path = path
      doc.title = filename
    }
    try await Backend.shared.save(doc.code, to: path)
    doc.isDirty = false
    saveSession()
    await refreshScriptManifest()
  }
```

When `doc.path` is nil the method derives a filename from `doc.title`
(`"Untitled"` → `"Untitled.rkt"`), writes to it, and sets `doc.path` —
without checking whether the file already exists or asking the user for a name.

### `EditorStore.swift:99-108`

```swift
func execute() async {
    guard let doc = activeDocument, !doc.isEvaluating else { return }
    if doc.isDirty {
      do {
        try await save(doc)
      } catch {
        doc.appendOutput("Save failed: \(error.localizedDescription)", stream: .stderr)
        return
      }
    }
```

`execute()` calls `save()` unconditionally for dirty documents. For an
untitled document that has never been saved, this triggers the implicit
`Untitled.rkt` save described above. The temp-file fallback on lines 111-121
is never reached because `save()` has already set `doc.path`.

## Impact

Any existing `Untitled.rkt` in the root directory is silently overwritten when
the user runs a new unsaved document. This can cause data loss with no warning.

## Suggested Fix

When `execute()` encounters an untitled document (`doc.path == nil`), skip the
`save()` call and instead use the existing temp-file path (lines 111-121),
which already handles running without persisting. If the document is also
dirty, write the current code to the temp file.

To handle the explicit-save case (`save()` called directly on an untitled
document, e.g. via Cmd-S), surface a save-as dialog so the user can choose a
filename instead of defaulting to `Untitled.rkt`.

## Related

- None
