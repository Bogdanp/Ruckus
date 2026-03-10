# Inject EditorSettings via Environment Instead of Per-View @State

## Summary

`EditorSettings` is created as `@State private var editorSettings =
EditorSettings()` inside `ContentView`. Although it reads from UserDefaults
internally, it is a standalone instance — not shared. If settings were ever
modified from a different code path (e.g. a URL scheme or shortcut), this
instance would not reflect the change. It also adds unnecessary state to
ContentView.

## Affected Code

### `ContentView.swift:7`

```swift
@State private var editorSettings = EditorSettings()
```

Created locally, then passed down to `CodeEditingView` and `SettingsView`
by value.

### `RuckusApp.swift:8-11`

```swift
WindowGroup {
  ContentView()
    .environment(EditorStore.shared)
}
```

`EditorStore` is injected here, but `EditorSettings` is not.

## Impact

No bug today because settings only change from the settings sheet (which
holds a reference to the same instance). But the pattern is inconsistent with
how `EditorStore` is handled, and it means `EditorSettings` cannot be accessed
from views that don't receive it explicitly.

## Suggested Fix

Create a shared instance and inject it like `EditorStore`:

```swift
// RuckusApp.swift
WindowGroup {
  ContentView()
    .environment(EditorStore.shared)
    .environment(EditorSettings.shared)
}

// EditorSettings.swift
@Observable
final class EditorSettings {
  static let shared = EditorSettings()
  ...
}

// ContentView.swift
@Environment(EditorSettings.self) private var editorSettings
```

## Related

- Task 04 (split ContentView) — removing this @State is part of simplifying ContentView.
