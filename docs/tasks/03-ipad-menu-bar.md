# Support the iPad menu bar

## Summary

The app has no menu bar support. On iPad with a hardware keyboard, iPadOS
displays a system menu bar at the top of the screen. SwiftUI apps populate it
via the `.commands` modifier on `WindowGroup`. Currently `RuckusApp` declares a
bare `WindowGroup` with no `.commands`, so the menu bar is empty aside from
system-provided entries.

All the user-facing actions already exist in the `titleMenu()` dropdown and the
toolbar in `ContentView.swift`, but none of them are surfaced in the menu bar
or have keyboard shortcuts (except Format which has Cmd+Shift+I).

## Affected Code

### `RuckusApp.swift:7-15`

```swift
var body: some Scene {
  WindowGroup {
    ContentView()
      .modifier(SaveAction())
      .modifier(ShareAction())
      .environment(EditorStore.shared)
      .environment(EditorSettings.shared)
  }
}
```

No `.commands` modifier on the `WindowGroup`, so the iPad menu bar has no
app-specific entries.

### `ContentView.swift:105-160`

The `titleMenu()` function contains all the document actions (New, Open, Save,
Save As, Share, Revert, Find, Format, Undo, Redo) but they're only accessible
through the navigation title dropdown. These same actions should appear in the
menu bar with standard keyboard shortcuts.

### `ContentView.swift:174-205`

The toolbar contains Run/Stop and Output actions that should also have
menu bar entries and keyboard shortcuts (e.g. Cmd+R for Run, Cmd+. for Stop).

## Impact

On iPad with a keyboard, users have no way to discover or use keyboard
shortcuts for common actions. There's no File > New/Open/Save, no Edit >
Undo/Redo/Find, and no way to run scripts from the keyboard (other than
through the title menu, which requires a tap). This makes the app feel
incomplete on iPad compared to keyboard-first apps.

## Suggested Fix

Add a `.commands` modifier to the `WindowGroup` in `RuckusApp.swift` with
`CommandMenu` and `CommandGroup` entries. Map standard shortcuts to existing
actions.

```swift
var body: some Scene {
  WindowGroup {
    ContentView()
      .modifier(SaveAction())
      .modifier(ShareAction())
      .environment(EditorStore.shared)
      .environment(EditorSettings.shared)
  }
  .commands {
    fileCommands()
    editCommands()
    runCommands()
  }
}
```

Suggested menu structure and shortcuts:

**File menu** (`CommandGroup(replacing: .newItem)`):
- New — Cmd+N
- Open... — Cmd+O
- Save — Cmd+S
- Save As... — Cmd+Shift+S
- Revert — (no shortcut)
- Share... — (no shortcut)

**Edit menu** (`CommandGroup(after: .undoRedo)`):
- Find... — Cmd+F
- Format — Cmd+Shift+I (already exists on `titleMenu`)

**Run menu** (`CommandMenu("Run")`):
- Run — Cmd+R
- Stop — Cmd+.

The commands need access to `EditorStore.shared`, `SaveAction`, and
`ShareAction` to call the same underlying methods. Since `.commands` is at the
scene level, use `@FocusedValue` or access the singletons directly
(`EditorStore.shared`).

## Related

- `ContentView.swift` — the `titleMenu()` and toolbar should stay in sync with
  the menu bar (ideally share action definitions to avoid duplication).
