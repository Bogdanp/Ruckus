# Incremental script manifest refresh

## Summary

`EditorStore.refreshScriptManifest` performs a BFS traversal of the
entire file tree via `Backend.shared.listFiles` on every save. With a
large number of files this is wasted work when only one file changed.

## Affected Code

### `Ruckus/Models/EditorStore.swift:320-338`

```swift
private func refreshScriptManifest() async {
    guard let root = try? await Backend.shared.getRootPath() else { return }
    var scripts = [String]()
    var queue = [root]
    while !queue.isEmpty {
        let dir = queue.removeFirst()
        let entries = (try? await Backend.shared.listFiles(atPath: dir)) ?? []
        for entry in entries {
            ...
        }
    }
    ScriptManifest.update(rootPath: root, scripts: scripts)
}
```

Called from `save`, `importFile`, and `restoreSession`.

## Suggested Fix

Track the manifest incrementally:

- On save/import: add or update the single path that changed.
- On delete: remove the single path.
- On restore: do one full scan (current behavior) to seed the list.

Add an `addScript(_:)` / `removeScript(_:)` method to `ScriptManifest`
alongside the existing `update(rootPath:scripts:)`. Call the incremental
methods from save/import/delete and reserve the full scan for restore.
