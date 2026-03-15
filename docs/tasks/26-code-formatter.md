# Expose the Racket code formatter in the UI

## Summary

A `format-program` RPC already exists in `ruckus-core/format.rkt` and its
Swift binding is generated in `Backend.swift`, but the formatter is not yet
wired into the editor UI. Users have no way to invoke it.

## Affected Code

### `Ruckus/Views/ContentView.swift:98-148`

```swift
Menu {
    // New, Open, Save, Save As, Share, Revert, Find, Undo, Redo
    // ...no Format action
}
```

The title menu has no "Format" action.

### `Ruckus/Models/EditorStore.swift`

There is no method to call the `formatProgram` RPC and apply the result to
the active document.

## Impact

Users cannot auto-format their code. This is especially painful on an iPad
where manual reformatting with a touch keyboard is tedious. The backend
capability is there but unreachable.

## Suggested Fix

1. **Add `formatActiveDocument()` to `EditorStore.swift`:**

   ```swift
   func formatActiveDocument() async {
       guard let doc = activeDocument else { return }
       do {
           let formatted = try await Backend.shared.formatProgram(doc.code)
           doc.code = formatted
       } catch {
           doc.appendOutput("Format failed: \(error.localizedDescription)",
                            stream: .stderr)
       }
   }
   ```

2. **Add a "Format" menu item** in `ContentView.swift`'s title menu:

   ```swift
   Button("Format") {
       Task { await editorStore.formatActiveDocument() }
   }
   .keyboardShortcut("i", modifiers: [.command, .shift])
   ```

## Related

- None
