# Improve CompletionController test coverage

## Summary

`CompletionController` is at 38.1% line coverage (40/105 lines). The existing
tests cover `scanIdentifiers`, popover lifecycle (`setPopover`, `tearDown`,
`dismiss`), `updatePalette`, and `attachIfNeeded`. The two main untested
methods are `updatePopover` (lines 38-61) and `currentWordPrefix` (lines
106-124), which together account for most of the missing coverage. Both
require a Runestone `TextView` instance, which makes them harder to reach
from unit tests.

## Affected Code

### `Ruckus/Views/Editor/CompletionController.swift:38-61`

```swift
func updatePopover(text: String, for textView: TextView) {
  guard let popover else { return }
  let prefix = currentWordPrefix(text: text, in: textView)
  let filtered: [String]
  if prefix.isEmpty {
    filtered = []
  } else {
    var seen = Set<String>()
    var results = [String]()
    for item in allCompletions where item.hasPrefix(prefix) && item != prefix {
      if seen.insert(item).inserted { results.append(item) }
    }
    for item in scanIdentifiers(in: text) where item.hasPrefix(prefix) && item != prefix {
      if seen.insert(item).inserted { results.append(item) }
    }
    filtered = results
  }
  guard !filtered.isEmpty else {
    popover.dismiss()
    return
  }
  popover.update(items: Array(filtered.prefix(20)), prefix: prefix)
  positionPopover(popover, in: textView)
}
```

This method combines prefix extraction, completion filtering (from both
`allCompletions` and in-document identifiers), deduplication, and popover
positioning. None of these paths are tested.

### `Ruckus/Views/Editor/CompletionController.swift:106-124`

```swift
private func currentWordPrefix(text: String, in textView: TextView) -> String {
  guard let selectedRange = textView.selectedTextRange else { return "" }
  let cursorPos = textView.offset(
    from: textView.beginningOfDocument, to: selectedRange.start
  )
  guard cursorPos >= 0 else { return "" }
  let idx = text.index(
    text.startIndex, offsetBy: min(cursorPos, text.count)
  )
  var start = idx
  while start > text.startIndex {
    let prev = text.index(before: start)
    guard let scalar = text[prev].unicodeScalars.first,
          Self.wordChars.contains(scalar) else { break }
    start = prev
  }
  let prefix = String(text[start..<idx])
  return prefix.count >= 2 ? prefix : ""
}
```

This is `private` and depends on `textView.selectedTextRange` and
`textView.offset(from:to:)`, so it cannot be tested in isolation.

## Impact

The filtering logic (deduplication, prefix matching, the 20-item cap) and
word-prefix extraction are the core of the autocomplete UX. Regressions
here would break completions silently.

## Suggested Fix

Two approaches, in order of preference:

### Option A: Test via a real `TextView`

Runestone's `TextView` can be instantiated with a minimal
`TextViewState`. Set its text, programmatically set the cursor position,
then call `updatePopover`. Verify the popover's displayed items.

```swift
@Test func updatePopoverFiltersCompletions() {
  let ctrl = CompletionController()
  let popover = CompletionPopover { _ in }
  ctrl.setPopover(popover)
  ctrl.allCompletions = ["define", "display", "displayln"]

  let state = TextViewState(text: "(dis", language: .plainText)
  let textView = TextView(state: state)
  // position cursor at end
  textView.selectedTextRange = textView.textRange(
    from: textView.endOfDocument, to: textView.endOfDocument
  )
  ctrl.updatePopover(text: "(dis", for: textView)
  // popover should show "display", "displayln" but not "define"
}
```

If `TextView` setup proves too brittle, fall back to Option B.

### Option B: Extract prefix logic into a testable helper

Change `currentWordPrefix` from `private` to `internal` (or extract the
pure string logic into a free function) so it can be tested directly:

```swift
// Internal for testing.
func wordPrefix(in text: String, cursorOffset: Int) -> String { ... }
```

Then test the filtering logic by calling `updatePopover` with a known
prefix via the extracted helper.

## Related

- None.
