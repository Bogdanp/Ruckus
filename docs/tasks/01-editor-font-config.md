# Configurable Editor Font

## Summary

The editor font is hard-coded to the system monospaced font at a fixed size.
Users should be able to pick a monospace font family and adjust the font size
to suit their preferences.

## Affected Code

### `Ruckus/Views/CodeEditingView.swift:30-40`

```swift
func makeUIView(context: Context) -> TextView {
    let textView = TextView(frame: .zero)
    ...
    let state = TextViewState(text: text, theme: DefaultTheme(), language: .racket)
    textView.setState(state)
```

The `TextView` is configured with no user-controlled font settings. The theme
(`DefaultTheme`) likely bakes in a fixed font.

### `Ruckus/Models/EditorDocument.swift:34`

```swift
.font: UIFont.monospacedSystemFont(ofSize: UIFont.smallSystemFontSize, weight: .regular)
```

Another hard-coded font reference used for document attributes.

### `Ruckus/Views/SettingsView.swift`

There is currently no editor section in settings where font preferences could
live.

## Impact

Users with different visual needs or preferences cannot adjust the code font.
The fixed size may be too small on larger iPads or too large on smaller phones.

## Suggested Fix

1. Add a `Settings` model (e.g. backed by `@AppStorage`) with `editorFontName`
   and `editorFontSize` properties, defaulting to the system monospace font and
   current size.
2. Add an "Editor" section to `SettingsView` with a font-size stepper and a
   picker listing available monospace fonts (`UIFont.familyNames` filtered to
   monospaced families).
3. Read these settings in `CodeEditingView.makeUIView` and apply them to the
   Runestone `TextView` theme/configuration.
4. Update `EditorDocument` to respect the same settings.

## Related

- `docs/tasks/02-editor-spacing.md` (also touches editor layout)
