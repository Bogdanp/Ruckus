# Silent Failures in Share

## Summary

The `share()` function in `ContentView` uses `try?` to ignore errors from file
system operations. If the temporary directory can't be created or the file
can't be written, the function silently proceeds and presents a share sheet
with a URL pointing to a nonexistent file.

## Affected Code

### `ContentView.swift:186-194`

```swift
private func share() {
    guard let doc = store.activeDocument else { return }
    let filename = doc.title.hasSuffix(".rkt") ? doc.title : doc.title + ".rkt"
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    let fileURL = tempDir.appendingPathComponent(filename)
    try? doc.code.write(to: fileURL, atomically: true, encoding: .utf8)
    shareFileURL = fileURL
}
```

Both `try?` calls swallow errors:

1. **Line 190**: `createDirectory` — if the temp directory can't be created
   (disk full, permissions issue), execution continues.
2. **Line 192**: `write(to:...)` — if the file can't be written (because the
   directory doesn't exist from step 1, or disk is full), execution continues.
3. **Line 193**: `shareFileURL` is set to a URL pointing to a file that may
   not exist.

### `ContentView.swift:75-77`

```swift
.sheet(item: $shareFileURL) { url in
    ActivitySheet(items: [url])
}
```

The `ActivitySheet` receives the potentially-invalid URL. UIKit's
`UIActivityViewController` will attempt to read the file and either:
- Show an empty/broken share sheet
- Silently fail to share
- In some cases, crash on certain share extensions that expect valid data

## Reproduction Scenario

1. Fill device storage to near capacity.
2. Open a document and tap Share.
3. `createDirectory` or `write` fails silently.
4. Share sheet appears but sharing fails or shows empty content.

This is also reproducible if there's a permissions issue with the temporary
directory, though this is unlikely in normal iOS operation.

## Impact

- User thinks they shared a file but the recipient gets nothing.
- No feedback that anything went wrong.
- Temporary directory creation failure cascades into file write failure, making
  the entire operation silently broken.

## Suggested Fix

Handle errors and show user feedback:

```swift
private func share() {
    guard let doc = store.activeDocument else { return }
    let filename = doc.title.hasSuffix(".rkt") ? doc.title : doc.title + ".rkt"
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    do {
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let fileURL = tempDir.appendingPathComponent(filename)
        try doc.code.write(to: fileURL, atomically: true, encoding: .utf8)
        shareFileURL = fileURL
    } catch {
        doc.appendOutput("Share failed: \(error.localizedDescription)", stream: .stderr)
    }
}
```

Alternatively, show an alert instead of writing to the output panel, since the
user's intent was to share rather than run code.

Also consider cleaning up the temp directory after the share sheet is
dismissed:

```swift
.sheet(item: $shareFileURL) { url in
    ActivitySheet(items: [url])
}
.onChange(of: shareFileURL) { oldURL, _ in
    if let oldURL {
        try? FileManager.default.removeItem(at: oldURL.deletingLastPathComponent())
    }
}
```
