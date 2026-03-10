# Consolidate Sheet State Into an Enum

## Summary

ContentView uses four separate `@State` booleans to track which sheet is
presented: `showFileBrowser`, `showSaveBrowser`, `showSettings`, and
`showOutput`. This allows impossible states (multiple sheets true at once)
and clutters the view with repetitive `.sheet(isPresented:)` modifiers.

## Affected Code

### `ContentView.swift:9-11,14-15`

```swift
@State private var showFileBrowser = false
@State private var showSaveBrowser = false
...
@State private var showSettings = false
@State private var showOutput = false
```

### `ContentView.swift:60-97`

Four `.sheet(isPresented:)` modifiers, one per boolean:

```swift
.sheet(isPresented: $showOutput) { ... }
.sheet(isPresented: $showSettings) { ... }
.sheet(isPresented: $showFileBrowser) { ... }
.sheet(isPresented: $showSaveBrowser) { ... }
```

## Impact

- Four independent booleans can theoretically all be `true` simultaneously.
- Each sheet dismissal requires SwiftUI to independently manage each binding.
- Adding a new sheet means adding another `@State` bool and another
  `.sheet(isPresented:)` block.

## Suggested Fix

Replace with an optional enum and a single `.sheet(item:)`:

```swift
enum ActiveSheet: Identifiable {
  case output
  case settings
  case fileBrowser
  case saveBrowser

  var id: Self { self }
}

@State private var activeSheet: ActiveSheet?

// In body:
.sheet(item: $activeSheet) { sheet in
  switch sheet {
  case .output:
    if let doc = store.activeDocument {
      OutputSheetView(text: doc.output)
    }
  case .settings:
    SettingsView(settings: editorSettings)
  case .fileBrowser:
    FileBrowserSheet { ... }
  case .saveBrowser:
    SaveBrowserSheet(initialFilename: saveFilename) { ... }
  }
}
```

Note: the `shareFileURL` sheet uses `.sheet(item:)` already and can stay
separate since it's driven by data (a URL), not a mode.

## Related

- Task 04 (split ContentView) — this is a step toward simplifying ContentView state.
