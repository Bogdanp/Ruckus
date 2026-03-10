# Split ContentView Into Smaller Components

## Summary

`ContentView` is 264 lines with 9 `@State` variables managing unrelated
concerns: file browsing, save-as flow, sharing, output sheet, settings, and
undo. This makes the view hard to reason about and difficult to test any
single behavior in isolation.

## Affected Code

### `ContentView.swift:5-15`

```swift
struct ContentView: View {
  @Environment(EditorStore.self) private var store
  @State private var editorSettings = EditorSettings()
  @State private var editorUndoManager: UndoManager?
  @State private var showFileBrowser = false
  @State private var showSaveBrowser = false
  @State private var saveFilename = ""
  @State private var shareFileURL: URL?
  @State private var shareError: String?
  @State private var showSettings = false
  @State private var showOutput = false
```

Nine `@State` properties controlling six different features.

### `ContentView.swift:137-258`

The `titleMenu()`, `leadingToolbar()`, `trailingToolbar()`, `save()`,
`saveAs()`, and `share()` methods add ~120 lines of logic that is tightly
coupled to the state variables above.

## Impact

- Hard to understand what state belongs to which feature.
- Toolbar, menu, and sheet code all in one place makes diffs noisy.
- Cannot test sharing or save-as logic without the full ContentView.

## Suggested Fix

Extract toolbar and menu content into separate views or methods that own
their relevant state. For example:

1. Extract `share()` + `shareFileURL` + `shareError` into a `ShareAction`
   helper or a small view modifier that manages its own state.
2. Extract `save()` / `saveAs()` + `saveFilename` + `showSaveBrowser` into a
   `SaveCoordinator` or similar.
3. Keep ContentView as the composition root that wires these together.

The goal is not to create abstractions for their own sake, but to reduce the
number of `@State` properties in ContentView to those that genuinely belong
at that level (e.g. `showOutput`, `showSettings`).

## Related

- Task 05 (EditorSettings at app level) would remove one more @State.
