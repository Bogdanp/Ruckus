# Export Logs

## Summary

The app uses structured `os.Logger` logging across several subsystems (backend,
editor, session), but there is no user-facing way to export these logs. When
users encounter issues, they have no way to share diagnostic information.

## Affected Code

### `Ruckus/Extensions/Logger+App.swift`

```swift
extension Logger {
  static let backend = Logger(subsystem: "com.ruckus.app", category: "backend")
  static let editor = Logger(subsystem: "com.ruckus.app", category: "editor")
  static let session = Logger(subsystem: "com.ruckus.app", category: "session")
}
```

Logs are written via `os.Logger` but never surfaced to the user.

### `Ruckus/Views/SettingsView.swift`

No "Export Logs" or diagnostic option exists in settings.

## Impact

Debugging user-reported issues is difficult without access to device logs.
Users would need to connect to a Mac and use Console.app, which is not
practical for most people.

## Suggested Fix

1. Add an "Export Logs" button to `SettingsView` (in a "Diagnostics" or
   "Support" section).
2. Use `OSLogStore` to collect recent log entries for the `com.ruckus.app`
   subsystem:
   ```swift
   let store = try OSLogStore(scope: .currentProcessIdentifier)
   let position = store.position(date: Date().addingTimeInterval(-3600))
   let entries = try store.getEntries(at: position)
       .compactMap { $0 as? OSLogEntryLog }
       .filter { $0.subsystem == "com.ruckus.app" }
   ```
3. Format the entries as plain text and present a `ShareLink` or
   `UIActivityViewController` so the user can share or save the file.

## Related

- None
