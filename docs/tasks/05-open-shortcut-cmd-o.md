# Change Open shortcut from Cmd+Shift+O to Cmd+O

## Summary

The File > Open... menu item uses Cmd+Shift+O instead of the standard Cmd+O.
This is a workaround for an iPadOS 26 bug where adding a Cmd+O keyboard
shortcut to any `CommandGroup` causes the entire group to be suppressed, even
after the system's "Open..." item has been removed via
`builder.remove(menu: .open)` in `buildMenu(with:)`.

## Affected Code

### `AppCommands.swift:21`

```swift
.keyboardShortcut("o", modifiers: [.command, .shift])
```

Change to:

```swift
.keyboardShortcut("o")
```

## Impact

Users expect Cmd+O to open files. Cmd+Shift+O works but is non-standard.

## Suggested Fix

On a future iPadOS version where the Cmd+O conflict is resolved, change the
shortcut to `.keyboardShortcut("o")`. Test by verifying the File menu still
shows all items (New, Open, Save, Save As, Revert) after the change.

## Related

- The root cause is that iPadOS 26 reserves Cmd+O for the system "Open..."
  handler even after the menu item is removed via `buildMenu(with:)`. Any
  `CommandGroup` containing a conflicting shortcut is entirely suppressed.
