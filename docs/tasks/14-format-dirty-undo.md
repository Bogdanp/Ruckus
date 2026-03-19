# Formatting does not mark document dirty and breaks undo

## Summary

When a document is formatted via `formatActiveDocument()`, the resulting text
change is not registered with the text view's undo manager. The document is
also not marked dirty, so save and revert are unavailable. The user has no way
to undo a format operation or save/revert the formatted file.

## Affected Code

### `Ruckus/Models/EditorStore.swift:200-208`

```swift
func formatActiveDocument() async {
  guard let doc = activeDocument else { return }
  do {
    let formatted = try await Backend.shared.formatProgram(doc.code)
    doc.code = formatted
  } catch {
    doc.appendOutput("Format failed: \(error.localizedDescription)", stream: .stderr)
  }
}
```

The formatted text is assigned directly to `doc.code`. This triggers the
`DocumentObserver`, but never goes through `textViewDidChange`, so `isDirty`
is never set to `true`.

### `Ruckus/Views/Editor/DocumentObserver.swift:31-32`

```swift
if textView.text != document.code {
  self.onCodeChanged?(textView, document.code)
}
```

### `Ruckus/Views/Editor/CodeEditingView.swift:49-52`

```swift
coordinator.documentObserver.onCodeChanged = { [weak coordinator] textView, code in
  textView.text = code
  coordinator?.highlightController.refreshBracketHighlights(text: code, in: textView)
}
```

Setting `textView.text` directly replaces the entire backing store without
registering an undo action. Runestone's `TextView` (like `UITextView`) does
not fire `textViewDidChange` for programmatic `.text` assignments.

### `Ruckus/Views/Editor/CodeEditingView.swift:225-233`

```swift
func textViewDidChange(_ textView: TextView) {
  guard let currentDocument = documentObserver.currentDocument else { return }
  let text = textView.text
  currentDocument.code = text
  currentDocument.isDirty = true
  ...
}
```

This is the only place `isDirty` is set to `true`, and it is never called
during a format operation.

## Impact

After formatting a document:
- The document is not marked dirty — the tab shows no unsaved indicator.
- Save is unavailable (the save action checks `isDirty`).
- Revert is unavailable (`canRevert` requires `isDirty`).
- Undo does not restore the pre-format text because no undo action was
  registered with the text view's undo manager.

The user's only recourse is to close the file without saving and reopen it,
losing any other unsaved edits.

## Suggested Fix

Replace the direct `textView.text = code` assignment in `onCodeChanged` with
an undoable text replacement through the text view's editing API:

1. **Use `textView.replace(_:withText:)` or select-all + `insertText`** so
   the replacement goes through Runestone's undo manager. For example:

   ```swift
   coordinator.documentObserver.onCodeChanged = { [weak coordinator] textView, code in
     let fullRange = NSRange(location: 0, length: (textView.text as NSString).length)
     // Save and restore the cursor position proportionally.
     let savedOffset = textView.selectedRange.location
     textView.selectedRange = fullRange
     textView.insertText(code)
     // Restore a reasonable cursor position.
     let newLength = (code as NSString).length
     textView.selectedRange = NSRange(
       location: min(savedOffset, newLength), length: 0
     )
     coordinator?.highlightController.refreshBracketHighlights(text: code, in: textView)
   }
   ```

   This registers an undo action automatically and fires `textViewDidChange`,
   which sets `isDirty = true`.

2. **Alternative**: keep the direct `.text` assignment for performance but
   manually register the undo action and set `isDirty`:

   ```swift
   let oldCode = textView.text
   textView.text = code
   document.isDirty = true
   textView.undoManager?.registerUndo(withTarget: textView) { tv in
     tv.text = oldCode
     document.isDirty = oldCode != savedCode
   }
   ```

   This is more complex and fragile (must keep undo/redo chains consistent),
   so option 1 is preferred if Runestone handles large replacements well.

## Related

- None.
