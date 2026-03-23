# Test EditorStore.save filename validation

## Summary

`EditorStore.save(_:)` contains inline filename validation logic
(checking for `/` and `..`) that is only exercised through integration
tests requiring a running Backend. The validation branch for invalid
filenames is not covered. Additionally, the filename normalization
(appending `.rkt`) is duplicated from `SaveBrowserSheet.normalizeFilename`
and untested at this layer.

## Affected Code

### `Models/EditorStore.swift:78-96`

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
        path = root.appendingPathComponent(filename)
        doc.path = path
        doc.title = filename
    }
    try await Backend.shared.save(doc.code, to: path)
    doc.isDirty = false
    saveSession()
    ScriptManifest.add(scriptAtPath: path)
}
```

The `guard` on line 85 is never hit in existing tests because all test
documents use well-formed titles.

## Impact

If filename validation regresses, a user could create a document with
`../` in the title that writes outside the sandbox root.

## Suggested Fix

Add tests in `EditorStoreTests` that:

1. Create a store, call `newDocument()`, set `doc.title` to `"bad/name"`,
   call `save(doc)`, and verify it throws `SaveError.invalidFilename`.
2. Same with `"bad..name"`.
3. Verify that a title without `.rkt` gets the suffix appended after save.
4. Verify that a title already ending in `.rkt` is left unchanged.

## Related

- None
