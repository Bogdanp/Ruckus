# Add editor color themes

## Summary

The editor uses Runestone's `DefaultTheme` for all syntax highlighting colors,
with no option for the user to choose between themes. There is no dark/light
theme toggle or alternative color schemes.

## Affected Code

### `Ruckus/Themes/EditorTheme.swift:5`

```swift
private let base = DefaultTheme()
```

All colors are delegated to this single hardcoded theme.

### `Ruckus/Models/EditorSettings.swift`

Stores font size and font family but has no theme preference.

## Impact

Users have no control over the editor's color palette. The default theme may
not suit all preferences or lighting conditions.

## Suggested Fix

1. **Define a theme protocol/enum** — create 3-4 built-in themes (e.g.
   Default, Solarized Dark, Solarized Light, Monokai) that each implement
   Runestone's `Theme` protocol with different color mappings.
2. **Add theme picker to EditorSettingsView** — let users select their
   preferred theme alongside font size and family.
3. **Persist in EditorSettings** — store the selected theme name in
   `UserDefaults` and apply on launch.
4. **Respect system appearance** — optionally auto-switch between a light and
   dark variant based on the system setting.

## Related

- Task 04: Rainbow parentheses — bracket colors must be defined per theme.
