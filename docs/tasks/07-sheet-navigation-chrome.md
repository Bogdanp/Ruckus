# Extract Shared Sheet Navigation Chrome Into a ViewModifier

## Summary

Multiple sheet views repeat the same NavigationStack + title + Done button
pattern. This boilerplate can be extracted into a reusable modifier.

## Affected Code

### `OutputSheetView.swift:8-19`

```swift
NavigationStack {
  OutputTextView(text: text)
    .presentationDragIndicator(.visible)
    .navigationTitle("Output")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button("Done") { dismiss() }
      }
    }
}
```

### `SettingsView.swift:10-55`

```swift
NavigationStack {
  List { ... }
    .presentationDragIndicator(.visible)
    .navigationTitle("Settings")
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button("Done") { dismiss() }
      }
    }
}
```

### `FolderBrowser.swift:21-68`

```swift
NavigationStack {
  VStack(spacing: 0) { ... }
    .navigationTitle(navigationTitle)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        ...
        Button(dismissLabel) { dismiss() }
        ...
      }
    }
}
```

FolderBrowser is slightly different (cancellationAction placement, conditional
back button), so it may not benefit from this extraction.

## Impact

Pure boilerplate reduction — no behavior change. Each new sheet currently
requires re-typing the NavigationStack wrapper.

## Suggested Fix

Create a `ViewModifier` or a small wrapper view:

```swift
struct SheetNavigation<Content: View>: View {
  let title: String
  var titleDisplayMode: NavigationBarItem.TitleDisplayMode = .inline
  var dismissLabel: String = "Done"
  @ViewBuilder var content: () -> Content
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      content()
        .presentationDragIndicator(.visible)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(titleDisplayMode)
        .toolbar {
          ToolbarItem(placement: .confirmationAction) {
            Button(dismissLabel) { dismiss() }
          }
        }
    }
  }
}
```

Usage:

```swift
SheetNavigation(title: "Output") {
  OutputTextView(text: text)
}
```

Only apply to sheets that follow the standard pattern (OutputSheetView,
SettingsView). FolderBrowser has custom toolbar logic and should keep its
own NavigationStack.

## Related

- None.
