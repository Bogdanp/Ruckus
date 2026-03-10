# Remove Unnecessary UserDefaults.synchronize() Calls

## Summary

`ScriptManifest` calls `.synchronize()` after writing to UserDefaults. This
has been unnecessary since iOS 12 — UserDefaults automatically persists
changes, and Apple's documentation explicitly discourages calling it.

## Affected Code

### `ScriptManifest.swift:15`

```swift
static func update(rootPath: String, scripts: [String]) {
  let store = defaults
  store?.set(rootPath, forKey: rootPathKey)
  store?.set(scripts, forKey: scriptsKey)
  store?.synchronize()
}
```

### `ScriptManifest.swift:23`

```swift
static func remove(script: String) {
  guard let store = defaults else { return }
  var current = scripts()
  current.removeAll { $0 == script }
  store.set(current, forKey: scriptsKey)
  store.synchronize()
}
```

## Impact

No correctness issue. The calls are harmless but misleading — they suggest
that UserDefaults needs manual flushing, which could lead to unnecessary
`synchronize()` calls being added elsewhere.

## Suggested Fix

Delete both `.synchronize()` lines.

## Related

- None.
