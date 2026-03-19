# Deduplicate path manipulation helpers

## Summary

The patterns `(root as NSString).appendingPathComponent(...)` and
`String(path.dropFirst(root.count).drop(while: { $0 == "/" }))` are
repeated across multiple files. A small extension would consolidate
them.

## Affected Code

### Relative path construction

- `Ruckus/Models/EditorStore.swift:348-349` — `relativePath(_:relativeTo:)`
- `RuckusShared/ScriptManifest.swift` — similar logic for widget paths

### Path joining via NSString bridge

- `Ruckus/Models/EditorStore.swift:88` — `(root as NSString).appendingPathComponent(filename)`
- `Ruckus/Models/EditorStore.swift:184`
- `Ruckus/Models/EditorStore.swift:252`
- `Ruckus/ViewModifiers/SaveAction.swift:14`

## Suggested Fix

Add a small `String` extension (e.g. in `Extensions/String+Path.swift`):

```swift
extension String {
    func appendingPathComponent(_ component: String) -> String {
        (self as NSString).appendingPathComponent(component)
    }

    func relativePath(from root: String) -> String {
        String(dropFirst(root.count).drop(while: { $0 == "/" }))
    }
}
```

Replace call sites with the extension methods and remove the private
`EditorStore.relativePath(_:relativeTo:)` static method.
