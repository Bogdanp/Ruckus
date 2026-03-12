# Parallelize refreshScriptManifest directory walk

## Summary

`EditorStore.refreshScriptManifest` walks the file tree using a sequential BFS
queue, awaiting `Backend.shared.listFiles(atPath:)` one directory at a time.
For a deep or wide directory tree this blocks the caller longer than necessary.

## Affected Code

### `Ruckus/Models/EditorStore.swift`

```swift
private func refreshScriptManifest() async {
  guard let root = try? await Backend.shared.getRootPath() else { return }
  var scripts = [String]()
  var queue = [root]
  while !queue.isEmpty {
    let dir = queue.removeFirst()
    let entries = (try? await Backend.shared.listFiles(atPath: dir)) ?? []
    for entry in entries {
      // ...
    }
  }
  ScriptManifest.update(rootPath: root, scripts: scripts)
}
```

## Suggested Fix

Use a `TaskGroup` to list child directories concurrently. Since the results
are collected into a flat `[String]` array, the order does not matter:

```swift
private func refreshScriptManifest() async {
  guard let root = try? await Backend.shared.getRootPath() else { return }
  let scripts = await collectScripts(under: root, relativeTo: root)
  ScriptManifest.update(rootPath: root, scripts: scripts)
}

private func collectScripts(under dir: String, relativeTo root: String) async -> [String] {
  let entries = (try? await Backend.shared.listFiles(atPath: dir)) ?? []
  return await withTaskGroup(of: [String].self) { group in
    var scripts = [String]()
    for entry in entries {
      switch entry {
      case .file(let file) where file.path.hasSuffix(".rkt"):
        scripts.append(Self.relativePath(file.path, relativeTo: root))
      case .folder(let folder):
        group.addTask { await self.collectScripts(under: folder.path, relativeTo: root) }
      default:
        break
      }
    }
    for await batch in group {
      scripts.append(contentsOf: batch)
    }
    return scripts
  }
}
```

The depth of the tree is typically small so unbounded concurrency is fine here.
