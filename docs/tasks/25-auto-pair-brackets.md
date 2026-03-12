# Auto-pair brackets on open bracket

## Summary

When the user types an opening bracket (`(`, `[`, or `{`), the editor should
automatically insert the matching closing bracket and place the cursor between
the two. This is standard behavior in most code editors and is especially
useful for Racket, where parentheses are typed constantly.

Similarly, typing a double-quote `"` should insert a matching closing quote.

## Affected Code

### `CodeEditingView.swift:169-182`

```swift
func textView(
  _ textView: TextView,
  shouldChangeTextIn range: NSRange,
  replacementText text: String
) -> Bool {
  guard text == "\n" || text == "\r\n" || text == "\r" else {
    return true
  }
  let source = textView.text
  let indent = indenter.indentForNewline(in: source, at: range.location)
  guard !indent.isEmpty else { return true }
  textView.insertText("\n" + indent)
  return false
}
```

The `shouldChangeTextIn` delegate currently only handles newline insertion for
auto-indentation. All other characters pass through unchanged, so there is no
bracket auto-pairing.

## Impact

Users must manually type every closing bracket, which slows down editing and
increases the chance of mismatched delimiters — especially in deeply nested
Racket code.

## Suggested Fix

Extend `shouldChangeTextIn` to detect opening delimiters and insert the
matching closer:

```swift
private static let pairs: [String: String] = [
  "(": ")", "[": "]", "{": "}", "\"": "\""
]

func textView(
  _ textView: TextView,
  shouldChangeTextIn range: NSRange,
  replacementText text: String
) -> Bool {
  // Auto-pair brackets.
  if let closer = Self.pairs[text] {
    textView.insertText(text + closer)
    // Move cursor back one position (between the pair).
    if let sel = textView.selectedRange {
      textView.selectedRange = NSRange(location: sel.location - 1, length: 0)
    }
    return false
  }

  // Existing newline / auto-indent logic.
  guard text == "\n" || text == "\r\n" || text == "\r" else {
    return true
  }
  let source = textView.text
  let indent = indenter.indentForNewline(in: source, at: range.location)
  guard !indent.isEmpty else { return true }
  textView.insertText("\n" + indent)
  return false
}
```

Additional considerations:

- **Skip-over on close:** When the character after the cursor is already the
  matching closer, typing it should skip over it instead of inserting a
  duplicate.
- **Quotes:** Only auto-pair `"` when not already inside a string. This may
  require checking the tree-sitter parse state.
- **Backspace:** Deleting an opening bracket when the closer is immediately
  after the cursor should delete both.

## Related

- None.
