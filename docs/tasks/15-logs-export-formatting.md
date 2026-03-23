# Test OSLogEntryLog.Level.description

## Summary

`LogsExport.swift` extends `OSLogEntryLog.Level` with a `description`
computed property that maps each log level to a string. This mapping is
currently at 23.4% coverage because the `Transferable` representation
requires an active `OSLogStore` to exercise. The `description` extension
is pure and can be tested directly.

## Affected Code

### `Views/Settings/LogsExport.swift:27-39`

```swift
extension OSLogEntryLog.Level {
    var description: String {
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

## Impact

If a level is mislabeled, exported logs would show the wrong severity,
making debugging harder.

## Suggested Fix

Add `LogsExportTests`:

1. Test each known level (`.undefined`, `.debug`, `.info`, `.notice`,
   `.error`, `.fault`) returns its expected string.
2. Test that the `default` branch handles the raw-value constructor
   (e.g., `OSLogEntryLog.Level(rawValue: 99)`) gracefully.

## Related

- None
