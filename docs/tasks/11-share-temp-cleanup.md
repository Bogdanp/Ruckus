# Clean up the final temporary share file

## Summary

`ShareAction` creates a unique temporary directory for each share operation,
but cleanup only happens when `shareFileURL` changes to another value. That
means the last shared temp directory survives after the sheet is dismissed.

This is not a catastrophic bug, but it creates unnecessary temp-file churn and
puts lifecycle cleanup in an indirect `onChange` path rather than in the share
flow itself.

## Affected Code

### `Ruckus/ViewModifiers/ShareAction.swift:8-17`

```swift
content
  .sheet(item: $shareFileURL) { item in
    ActivitySheet(items: [item.url])
  }
  .onChange(of: shareFileURL?.url) { oldURL, _ in
    if let oldURL {
      try? FileManager.default.removeItem(at: oldURL.deletingLastPathComponent())
    }
  }
```

Cleanup only runs for the previously shared item when the binding changes.
There is no matching cleanup when the final sheet presentation ends.

### `Ruckus/ViewModifiers/ShareAction.swift:29-37`

```swift
let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
do {
  try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
  let fileURL = tempDir.appendingPathComponent(filename)
  try document.code.write(to: fileURL, atomically: true, encoding: .utf8)
  shareFileURL = IdentifiableURL(url: fileURL)
} catch {
  shareError = error.localizedDescription
}
```

The share path allocates temp storage but does not define a full cleanup
policy for it.

## Impact

Repeated sharing leaves behind temp directories until the OS decides to clean
them up. More importantly, the code makes resource lifecycle harder to reason
about because cleanup is tied to state changes instead of the end of sharing.

## Suggested Fix

Track the active temp directory explicitly and remove it when sharing ends, not
just when a new share begins. Two reasonable approaches:

1. Use `onDismiss` for the sheet and delete the currently active temp
   directory there.
2. Wrap temp-file creation in a small helper object that owns the directory and
   exposes a single `cleanup()` method.

If future sharing needs grow, a reusable `TemporaryExportFile` helper would be
cleaner than managing UUID temp directories directly in the view modifier.

## Related

- None.
