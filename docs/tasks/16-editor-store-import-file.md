# Test EditorStore.importFile

## Summary

`EditorStore.importFile(from:)` has 0% coverage. It handles importing a
file from a URL (e.g. opened via the system file picker or shared from
another app), creating a document, copying the file to the Ruckus
sandbox, and updating the script manifest. None of these paths are
exercised in tests.

## Affected Code

### `Models/EditorStore.swift:175-198`

```swift
func importFile(from url: URL) async {
    let filename = url.lastPathComponent
    guard let content = try? String(contentsOf: url, encoding: .utf8) else {
        Logger.editor.warning("\(#function): failed to read imported file: \(url.lastPathComponent)")
        return
    }
    let root = try? await Backend.shared.getRootPath()
    let doc = EditorDocument(title: filename, code: content)
    if let root {
        let destPath = root.appendingPathComponent(filename)
        do {
            try await Backend.shared.save(content, to: destPath)
        } catch {
            Logger.editor.warning("\(#function): failed to save imported file: \(error)")
        }
        doc.path = destPath
    }
    documents.append(doc)
    activeDocumentID = doc.id
    saveSession()
    if let destPath = doc.path {
        ScriptManifest.add(scriptAtPath: destPath)
    }
}
```

## Impact

Import is a key user-facing feature (Open In / share sheet). Regressions
could silently drop imported files or fail to register them in the script
manifest.

## Suggested Fix

Add tests in `EditorStoreTests`:

1. Write a temp `.rkt` file to the filesystem, call
   `importFile(from: tempURL)`. Verify the document is created with the
   correct title, code, and path. Clean up the temp file and backend
   copy afterward.
2. Call `importFile` with a URL pointing to a nonexistent file. Verify
   no document is added (the `guard` early return).
3. Verify the imported document becomes the active document.

## Related

- None
