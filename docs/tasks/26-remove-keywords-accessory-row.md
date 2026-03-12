# Remove the keywords input accessory row

## Summary

The input accessory bar above the keyboard has two rows: a symbols row
(`(`, `)`, `[`, `]`, `"`, `#`, etc.) and a keywords row (`#lang`, `define`,
`let`, `if`, `cond`, etc.). Now that the completion popover provides keyword
suggestions from both base symbols and per-execution completions, the keywords
row is redundant. Removing it reclaims vertical screen space on the keyboard.

## Affected Code

### `Ruckus/Views/CodeEditingView.swift:25-31`

```swift
private static let keywords: [(label: String, text: String)] = [
  ("#lang", "#lang "),
  ("define", "define "), ("let", "let "),
  ("if", "if "), ("cond", "cond "),
  ("case", "case "), ("match", "match "),
  ("lambda", "lambda "), ("λ", "λ ")
]
```

This data is only used by the keywords row.

### `Ruckus/Views/CodeEditingView.swift:118-158`

```swift
private func makeInputAccessoryView(for textView: TextView) -> UIInputView {
  // ...
  let symbolsRow = makeSnippetRow(snippets: Self.symbols, for: textView)
  let keywordsRow = makeSnippetRow(snippets: Self.keywords, for: textView)

  let outerStack = UIStackView(arrangedSubviews: [symbolsRow, keywordsRow])
  outerStack.axis = .vertical
  outerStack.spacing = 4
  // ...
}
```

The outer stack uses two rows. With the keywords row removed, the stack can be
replaced by the single symbols row (no vertical stack needed), and the bar
height can shrink from 76pt to roughly 40pt.

## Impact

The keywords row takes up ~36pt of vertical space above the keyboard. Removing
it gives more room for the editor on small screens. The completion popover
already covers keyword insertion with richer, context-aware suggestions.

## Suggested Fix

1. Delete the `keywords` static property.
2. In `makeInputAccessoryView`, remove `keywordsRow` and the outer stack.
   Add `symbolsRow` directly to the bar.
3. Reduce the bar frame height from 76 to ~40 (or let auto-sizing handle it).
4. Verify the symbols row still scrolls horizontally and the filler view
   still covers the keyboard corners.
