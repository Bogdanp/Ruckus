# Add Missing iPad Menu Bar Items

## Summary

The iPad menu bar (`AppCommands`) is missing several actions that are available
in the title menu dropdown and toolbar. Users with a hardware keyboard expect
standard menu items like Find (Cmd+F), Close (Cmd+W), and Format to appear in
the menu bar, but currently only File (New, Open, Save, Save As, Revert), View
(Output), and Run (Run, Stop) are exposed.

## Affected Code

### `Ruckus/Commands/AppCommands.swift:1-73`

```swift
struct AppCommands: Commands {
  @FocusedValue(\.saveAction) private var saveAction
  @FocusedValue(\.openFile) private var openFile
  @FocusedValue(\.viewOutput) private var viewOutput

  private var store: EditorStore { EditorStore.shared }

  var body: some Commands {
    CommandGroup(replacing: .newItem) { ... }
    CommandGroup(replacing: .saveItem) { ... }
    CommandGroup(replacing: .toolbar) { ... }
    CommandMenu("Run") { ... }
  }
}
```

The following actions exist in the title menu (`ContentView.titleMenu`) or
toolbar but have no corresponding menu bar entry:

1. **Find** -- title menu has "Find..." triggering
   `editorFindInteraction?.presentFindNavigator(showingReplace: false)`.
   Expected shortcut: Cmd+F.
2. **Find and Replace** -- title menu has "Find and Replace..." triggering
   `presentFindNavigator(showingReplace: true)`. Expected shortcut:
   Cmd+Option+F.
3. **Format** -- title menu has an `AsyncButton` calling
   `store.formatActiveDocument()` with `.keyboardShortcut("i", modifiers:
   [.command, .shift])`. The shortcut only works when the title menu is open
   because it is not registered as a `CommandGroup` item.
4. **Share** -- title menu has "Share..." calling `shareAction.share()`. No
   menu bar equivalent.
5. **Close Tab** -- the tab bar close button calls `store.close(_:)` but there
   is no Cmd+W menu item to close the active tab.
6. **Settings** -- the leading toolbar has a gear button that opens the
   settings sheet, but there is no menu bar item for it.

### `Ruckus/Extensions/FocusedValues+App.swift:1-7`

```swift
extension FocusedValues {
  @Entry var saveAction: SaveActionHandler?
  @Entry var openFile: (@MainActor @Sendable () -> Void)?
  @Entry var viewOutput: (@MainActor @Sendable () -> Void)?
}
```

New focused values will be needed for `findAction`, `findAndReplaceAction`,
`formatAction`, `shareAction`, `closeAction`, and `settingsAction` so the
menu bar commands can reach the view layer.

## Impact

On iPad with a hardware keyboard, users expect standard shortcuts like Cmd+F,
Cmd+W, and Cmd+, to work. Currently they do nothing. The Format shortcut
(Cmd+Shift+I) only fires when the title menu dropdown is visible, which defeats
the purpose of a keyboard shortcut.

## Suggested Fix

Add the missing items to `AppCommands` and wire them through new focused values.

### 1. Edit menu -- Find, Find and Replace, Format

```swift
CommandGroup(after: .pasteboard) {
  Button {
    findAction?()
  } label: {
    Label("Find...", systemImage: "magnifyingglass")
  }
  .keyboardShortcut("f")
  .disabled(findAction == nil)
  Button {
    findAndReplaceAction?()
  } label: {
    Label("Find and Replace...", systemImage: "arrow.left.arrow.right")
  }
  .keyboardShortcut("f", modifiers: [.command, .option])
  .disabled(findAndReplaceAction == nil)
  Divider()
  Button {
    formatAction?()
  } label: {
    Label("Format", systemImage: "text.alignleft")
  }
  .keyboardShortcut("i", modifiers: [.command, .shift])
  .disabled(formatAction == nil)
}
```

### 2. File menu -- Share, Close

```swift
CommandGroup(after: .saveItem) {
  Button {
    shareAction?()
  } label: {
    Label("Share...", systemImage: "square.and.arrow.up")
  }
  .disabled(shareAction == nil)
  Divider()
  Button {
    closeAction?()
  } label: {
    Label("Close Tab", systemImage: "xmark")
  }
  .keyboardShortcut("w")
  .disabled(closeAction == nil)
}
```

### 3. App menu -- Settings

```swift
CommandGroup(after: .appSettings) {
  Button {
    settingsAction?()
  } label: {
    Label("Settings...", systemImage: "gearshape")
  }
  .keyboardShortcut(",")
  .disabled(settingsAction == nil)
}
```

### 4. New focused values

Add to `FocusedValues+App.swift`:

```swift
@Entry var findAction: (@MainActor @Sendable () -> Void)?
@Entry var findAndReplaceAction: (@MainActor @Sendable () -> Void)?
@Entry var formatAction: (@MainActor @Sendable () -> Void)?
@Entry var shareAction: (@MainActor @Sendable () -> Void)?
@Entry var closeAction: (@MainActor @Sendable () -> Void)?
@Entry var settingsAction: (@MainActor @Sendable () -> Void)?
```

Set corresponding `.focusedSceneValue` entries in `ContentView`.

### Note: shortcut conflicts

Some of the proposed shortcuts may conflict with built-in iPadOS/UIKit
shortcuts. In particular, **Cmd+F** is already handled by `UIFindInteraction`
on the text view, and **Cmd+W** may be claimed by the iPadOS 26 window
management system. Verify each shortcut at implementation time by testing on
a real device or simulator with a hardware keyboard, and pick alternatives for
any that conflict.

## Related

- None.
