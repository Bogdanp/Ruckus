# Test ScriptOutputCache

## Summary

`ScriptOutputCache` has 0% test coverage (17 executable lines). It is a small,
pure-logic enum in `RuckusShared` that persists script output and timestamps
via `UserDefaults`. All paths are straightforward to unit-test without mocking.

## Affected Code

### `RuckusShared/ScriptOutputCache.swift:1-29`

```swift
enum ScriptOutputCache {
  static let suiteName = "group.io.defn.Ruckus"
  static let widgetKind = "ScriptOutputWidget"

  private static let keyPrefix = "scriptOutput:"
  private static let timestampSuffix = ":timestamp"

  private static var defaults: UserDefaults? {
    UserDefaults(suiteName: suiteName)
  }

  static func save(output: String, for scriptId: String) {
    let store = defaults
    store?.set(output, forKey: keyPrefix + scriptId)
    store?.set(Date().timeIntervalSince1970, forKey: keyPrefix + scriptId + timestampSuffix)
  }

  static func load(for scriptId: String) -> (output: String, date: Date)? {
    guard let store = defaults,
          let output = store.string(forKey: keyPrefix + scriptId) else {
      return nil
    }
    let timestamp = store.double(forKey: keyPrefix + scriptId + timestampSuffix)
    guard timestamp > 0 else { return nil }
    return (output, Date(timeIntervalSince1970: timestamp))
  }
}
```

No tests exist for this type.

## Impact

Without tests, regressions in widget output caching (used by `ExecutionService`
to feed the `ScriptOutputWidget`) would go undetected.

## Suggested Fix

Add `RuckusTests/Models/ScriptOutputCacheTests.swift` with the following cases:

1. **Save/load round-trip** — save output for a script ID, load it back,
   verify the output string matches and the returned date is recent.
2. **Load returns nil for missing key** — call `load` for a script ID that
   was never saved; expect `nil`.
3. **Load returns nil when timestamp is zero/missing** — manually set the
   output key but not the timestamp key; expect `nil` from `load`.
4. **Overwrite** — save twice with different output; verify the second value
   wins.

Because `ScriptOutputCache` hard-codes its `suiteName`, tests will use the
real app-group suite. Each test should use a unique script ID (e.g. a UUID
string) and clean up its keys in a defer block to avoid polluting state.

## Related

- None.
