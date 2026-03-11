# Add rainbow parentheses

## Summary

Nested parentheses are the primary structural element in Racket code, but the
editor currently colors all parentheses the same. Rainbow parentheses assign
distinct colors to each nesting depth, making it much easier to visually match
opening and closing delimiters.

## Affected Code

### `Ruckus/Themes/EditorTheme.swift:26-28`

```swift
func textColor(for highlightName: String) -> UIColor? {
  base.textColor(for: highlightName)
}
```

The theme delegates all highlight colors to `DefaultTheme`. There is no
depth-aware coloring for bracket tokens.

### `vendor/tree-sitter-racket/queries/highlights.scm`

The tree-sitter queries capture parentheses but do not distinguish nesting
depth.

## Impact

Deeply nested expressions (common in Racket) are hard to read. Users must
count parentheses manually to understand structure.

## Suggested Fix

Tree-sitter does not natively support depth-based highlighting, so this
needs a custom approach:

1. **Post-process the syntax tree** — after tree-sitter parses the document,
   walk the tree to compute bracket depth and assign a color from a rotating
   palette (e.g. 6 colors).
2. **Apply via attributed text decorations** — use Runestone's decoration API
   or text storage attributes to overlay bracket colors.
3. **Color palette** — use visually distinct, accessible colors that work in
   both light and dark mode. Common choices: red, orange, yellow, green, blue,
   purple.

Also consider highlighting the matching bracket when the cursor is adjacent
to one (bracket matching).

## Related

- Task 06: Editor color themes — rainbow paren colors must coordinate with
  the selected theme to remain readable.
