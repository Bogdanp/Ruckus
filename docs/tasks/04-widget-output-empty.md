# Widget output is empty after script execution

## Summary

When a script is run from the editor, the widget configured for that script
shows empty output. The widget cache write path (`ScriptOutputCache.save`)
and read path (`ScriptOutputCache.load`) need to be traced to find where
the data is lost.

## Affected Code

### `Ruckus/AppDelegate.swift:38-46` — cache write (editor path)

```swift
private static func saveWidgetCache(executionId: UInt64, doc: EditorDocument) {
    let stdout = outputBuffers[executionId]?.stdout.decoded ?? ""
    guard let fullPath = doc.path,
          let root = ScriptManifest.rootPath(),
          fullPath.hasPrefix(root) else { return }
    let scriptId = String(fullPath.dropFirst(root.count).drop { $0 == "/" })
    ScriptOutputCache.save(output: stdout, for: scriptId)
    WidgetCenter.shared.reloadTimelines(ofKind: ScriptOutputCache.widgetKind)
}
```

Called from `step()` when execution is done (line 94). Several silent
early-return conditions: `doc.path` is nil (unsaved documents),
`ScriptManifest.rootPath()` is nil, or the path prefix doesn't match.

### `RuckusWidgets/ScriptWidgetProvider.swift:19-25` — cache read (widget path)

```swift
private func entry(for configuration: SelectScriptIntent) -> ScriptEntry {
    guard let scriptId = configuration.script?.id,
          let cached = ScriptOutputCache.load(for: scriptId) else {
      return ScriptEntry(date: .now, output: "Select a script", scriptId: configuration.script?.id)
    }
    return ScriptEntry(date: cached.date, output: cached.output, scriptId: scriptId)
}
```

Reads from the shared `UserDefaults` suite via `ScriptOutputCache.load`.
The `scriptId` comes from `ScriptEntity.id` which is the relative filename
(e.g. `hello.rkt`), matching the format produced by `saveWidgetCache`.

### `RuckusShared/ScriptOutputCache.swift` — shared cache

Uses `UserDefaults(suiteName: "group.io.defn.Ruckus")`. Both the app and
widget extension have the matching App Group entitlement.

## Impact

Widgets always show "Select a script" or empty text even after a script
has been run successfully from the editor.

## Suggested Fix

Debug by adding logging to `saveWidgetCache` to confirm it is reached and
that `stdout`, `doc.path`, `ScriptManifest.rootPath()`, and the derived
`scriptId` all have the expected values. Verify the UserDefaults write is
visible to the widget extension process (e.g. read back immediately after
write in a debug widget timeline entry). The root cause needs investigation.

## Related

- None
