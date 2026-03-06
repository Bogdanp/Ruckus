# Shortcuts Link in Settings

## Summary

Add a `ShortcutsLink` to the settings page so users can discover and manage
their Ruckus shortcuts directly from the app.

## Affected Code

### `Ruckus/Views/SettingsView.swift`

The settings list should include a `ShortcutsLink` row alongside the existing
"Rate Ruckus" and "About" entries.

## Scope

### 1. Shortcuts row

- Add a `ShortcutsLink()` (from the `AppIntents` framework) to the settings
  `List`. This is the standard SwiftUI view that Apple provides for linking
  to the app's shortcuts in the Shortcuts app.
- No manual URL schemes or `openURL` calls needed -- `ShortcutsLink` handles
  everything automatically.

## Impact

Users who set up App Shortcuts have no way to find or manage them from within
Ruckus. A `ShortcutsLink` provides the standard, Apple-recommended path to
the Shortcuts app.

## Suggested Fix

```swift
import AppIntents

// In SettingsView's List:
Section {
  ShortcutsLink()
}
```

## Related

- [13-settings-page](13-settings-page.md)
