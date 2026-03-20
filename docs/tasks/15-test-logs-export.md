# Test LogsExport level descriptions

## Summary

`LogsExport` has 0% test coverage (47 executable lines). It contains a
`fileprivate` extension on `OSLogEntryLog.Level` that maps each log
level to a human-readable string. This mapping is used when exporting
logs and a wrong label would make exported logs misleading.

## Affected Code

### `Ruckus/Views/Settings/LogsExport.swift:27-38`

```swift
extension OSLogEntryLog.Level {
  fileprivate var description: String {
    switch self {
    case .undefined: "undefined"
    case .debug: "debug"
    case .info: "info"
    case .notice: "notice"
    case .error: "error"
    case .fault: "fault"
    default: "default"
    }
  }
}
```

The `description` property is `fileprivate`, so it cannot be tested
directly from outside the file.

## Impact

A wrong level label would make exported logs harder to triage.

## Suggested Fix

Change `fileprivate` to `internal` (or move the extension to its own
file with internal access) so tests can call it.

Add `RuckusTests/Views/Settings/LogsExportTests.swift` with:

1. **Each known level** — verify `.undefined` → `"undefined"`,
   `.debug` → `"debug"`, `.info` → `"info"`, `.notice` → `"notice"`,
   `.error` → `"error"`, `.fault` → `"fault"`.

Optionally, if extraction is too disruptive, test the full export
format via `LogsExport.getRecentEntries()` (which queries the real
OSLog store in-process) — but this depends on whether the test process
has any matching log entries.

## Related

- None.
