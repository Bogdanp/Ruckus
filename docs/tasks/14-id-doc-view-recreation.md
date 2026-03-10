# Investigate .id(doc.id) Forcing Full View Recreation on Tab Switch

## Summary

ContentView applies `.id(doc.id)` to `CodeEditingView`, which forces SwiftUI
to destroy and recreate the entire UIViewRepresentable (including the
underlying `TextView`, input accessory, and completion popover) every time the
user switches tabs. This causes loss of UIKit state like scroll position,
selection, and undo history.

## Affected Code

### `ContentView.swift:45`

```swift
CodeEditingView(
  text: Binding(
    get: { doc.code },
    set: {
      doc.code = $0
      doc.isDirty = true
    }
  ),
  textViewUndoManager: $editorUndoManager,
  completions: doc.completions,
  settings: editorSettings
)
.id(doc.id)
```

The `.id(doc.id)` modifier tells SwiftUI that this view's identity changes
when the document changes, triggering a full teardown and rebuild.

### `CodeEditingView.swift:138-141`

```swift
static func dismantleUIView(_ textView: TextView, coordinator: Coordinator) {
  coordinator.popover?.removeFromSuperview()
  coordinator.popover = nil
}
```

This runs on every tab switch, removing and re-adding the popover.

## Impact

- Scroll position and text selection are lost on tab switch.
- Undo history is lost on tab switch (the undo manager belongs to the
  UITextView which is destroyed).
- The completion popover is removed and re-added to the window on every switch.
- A recent commit (b2b4416: "don't re-show output sheet on tab switch")
  suggests this recreation has already caused user-visible issues.

## Suggested Fix

Investigate whether `.id(doc.id)` can be removed by making `CodeEditingView`
properly handle document changes in `updateUIView`. The key change would be
resetting the text view's content in `updateUIView` when the document changes:

```swift
func updateUIView(_ textView: TextView, context: Context) {
  if textView.text != text {
    let state = TextViewState(text: text, theme: theme, language: .racket)
    textView.setState(state)
  }
  ...
}
```

This preserves the UIKit view instance (and its scroll position, undo
manager, etc.) while updating its content. The trade-off is that the
transition is less clean — the view might briefly show the old document's
scroll position before the new content appears. Test whether this is
acceptable UX.

If full recreation is intentional, consider at minimum saving and restoring
scroll position per document.

## Related

- Task 13 (DispatchQueue in CodeEditingView) — the popover lifecycle is
  affected by view recreation.
