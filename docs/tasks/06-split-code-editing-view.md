# Split CodeEditingView into smaller editor components

## Summary

`CodeEditingView` is doing too much in one `UIViewRepresentable` and one
coordinator. It owns UIKit editor construction, theme application, accessory
keyboard UI, document observation, completion popover behavior, bracket
highlighting, match flashing, and scroll/selection restoration.

The file is still readable today, but its current shape makes changes risky.
The document observation bridge is especially brittle because it relies on
recursive observation and `nonisolated(unsafe)` captures around an
`@Observable` model object.

## Affected Code

### `Ruckus/Views/CodeEditingView.swift:33-65`

```swift
func makeUIView(context: Context) -> TextView {
  let textView = TextView(frame: .zero)
  textView.editorDelegate = context.coordinator
  textView.showLineNumbers = true
  // editor configuration
  textView.inputAccessoryView = makeInputAccessoryView(for: textView)
  // theme creation
  let popover = CompletionPopover(font: settings.font) { suffix in
    textView.insertText(suffix)
  }
  context.coordinator.popover = popover
  context.coordinator.observeCode(of: document, in: textView)
  context.coordinator.updateBracketHighlights(in: textView)
  return textView
}
```

View construction is coupled to accessory UI, theme setup, completion UI, and
document observation.

### `Ruckus/Views/CodeEditingView.swift:160-206`

```swift
func updateUIView(_ textView: TextView, context: Context) {
  let coordinator = context.coordinator
  let font = settings.font

  let themeChanged = font != coordinator.currentFont
    || settings.themeName != coordinator.currentThemeName
  let highlightSettingsChanged = themeChanged
    || settings.rainbowParentheses != coordinator.rainbowEnabled

  if highlightSettingsChanged {
    coordinator.applyHighlightColors(from: settings)
  }

  if document !== coordinator.currentDocument {
    switchDocument(in: textView, coordinator: coordinator, font: font)
  } else if themeChanged {
    let theme = EditorTheme(font: font, palette: settings.colorPalette)
    textView.theme = theme
    textView.backgroundColor = theme.backgroundColor
  }
  // more theme, popover, undo, and find syncing
}
```

This update path mixes several independent responsibilities and is hard to
verify.

### `Ruckus/Views/CodeEditingView.swift:254-268`

```swift
func observeCode(of document: EditorDocument, in textView: TextView) {
  nonisolated(unsafe) let document = document
  nonisolated(unsafe) weak let weakDocument = document
  withObservationTracking {
    _ = document.code
  } onChange: { [weak self, weak textView] in
    Task { @MainActor in
      guard let self, let textView,
            let document = weakDocument,
            document === self.currentDocument else { return }
      if textView.text != document.code {
        textView.text = document.code
      }
      self.observeCode(of: document, in: textView)
    }
  }
}
```

The observation bridge is subtle and easy to break during future edits.

## Impact

Simple changes to completions, theming, or selection behavior require touching
the same large file and coordinator state bag. That raises regression risk in
the editor, which is the app's highest-value surface.

## Suggested Fix

Split the implementation into smaller pieces with explicit ownership, for
example:

- `EditorTextViewFactory` or helper methods for base UIKit configuration
- `EditorThemeController` for theme and insertion-point updates
- `EditorCompletionController` for popover and prefix filtering
- `EditorHighlightController` for rainbow and matching bracket behavior
- a narrower document-sync bridge that handles only text/state restoration

If the team wants to keep a single file, at least extract the coordinator
subsystems into nested helper types so state is not all stored on one class.

Add focused tests around the extracted logic where possible, especially for
completion filtering, match highlighting decisions, and document switching.

## Related

- None.
