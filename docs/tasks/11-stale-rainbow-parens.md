# Stale Rainbow Parentheses After Formatting

## Summary

When the user formats a document (via `formatActiveDocument()`), the text changes but the rainbow parenthesis highlights are not recalculated. The old highlights remain, positioned according to the pre-format text, causing them to appear on wrong characters or at invalid positions.

The root cause is that `DocumentObserver` sets `textView.text` programmatically, which does not trigger the `textViewDidChange` delegate callback. Since `updateBracketHighlights` is only called from `textViewDidChange`, the rainbow ranges are never refreshed for programmatic text changes.

## Affected Code

### `DocumentObserver.swift:26-28`

```swift
if textView.text != document.code {
  textView.text = document.code
}
```

Setting `textView.text` programmatically does not fire `textViewDidChange`. No call to `highlightController.updateBracketHighlights` follows this assignment, so the cached rainbow ranges from the previous text remain applied to the new text.

### `CodeEditingView.swift:221-230`

```swift
func textViewDidChange(_ textView: TextView) {
  guard let currentDocument = documentObserver.currentDocument else { return }
  let text = textView.text
  currentDocument.code = text
  currentDocument.isDirty = true
  didType = true
  highlightController.clearMatchState()
  highlightController.updateBracketHighlights(text: text, in: textView)
  completionController.updatePopover(text: text, for: textView)
}
```

This is the only path that refreshes rainbow highlights after a text change, but it only fires for user-initiated edits, not programmatic ones.

## Impact

After formatting a document whose content actually changes, rainbow parenthesis highlights are stale — they highlight wrong characters, appear at incorrect positions, or show colors for the old nesting structure. The highlights remain incorrect until the user types something (triggering `textViewDidChange`).

## Suggested Fix

After setting `textView.text` in `DocumentObserver`, the coordinator needs to refresh bracket highlights. The simplest approach is to have `DocumentObserver` call a closure when text is programmatically updated, and wire that closure to refresh highlights:

**Option A — Notification closure on DocumentObserver:**

Add a callback to `DocumentObserver` that fires after programmatic text updates:

```swift
// DocumentObserver.swift
var onTextApplied: ((TextView) -> Void)?

// In observeCode, after setting textView.text:
if textView.text != document.code {
  textView.text = document.code
  self.onTextApplied?(textView)
}
```

Then in the Coordinator, wire it up:

```swift
documentObserver.onTextApplied = { [weak self] textView in
  self?.highlightController.clearMatchState()
  self?.highlightController.updateBracketHighlights(in: textView)
}
```

**Option B — Call updateBracketHighlights directly in DocumentObserver:**

Pass the `HighlightController` into `DocumentObserver` and call `updateBracketHighlights` directly after the text assignment. This is simpler but couples the observer to highlighting.

Option A is preferred as it keeps `DocumentObserver` decoupled from highlighting concerns.

## Related

- None
