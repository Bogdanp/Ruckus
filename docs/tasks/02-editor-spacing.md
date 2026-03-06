# Improve Editor Spacing

## Summary

The code editor feels cramped. There is not enough padding around the text
content, and the line-number gutter sits too close to the code, making it
harder to read.

## Affected Code

### `Ruckus/Views/CodeEditingView.swift:29-44`

```swift
func makeUIView(context: Context) -> TextView {
    let textView = TextView(frame: .zero)
    textView.editorDelegate = context.coordinator
    textView.showLineNumbers = true
    ...
```

The `TextView` is created with default spacing. No `textContainerInset`,
gutter width, or line spacing overrides are applied.

## Impact

The lack of padding makes the editor feel tight, especially on smaller screens.
The line numbers bleeding into the code area reduces readability.

## Suggested Fix

1. Add horizontal padding to the text container so code does not start flush
   against the gutter or the right edge. Runestone's `TextView` supports
   `textContainerInset` — set left/right insets (e.g. 4-8 pt).
2. Increase the gap between the line-number gutter and the code area. Check if
   Runestone exposes a `gutterTrailingPadding` or similar property; if not,
   adjust `textContainerInset.left` to compensate.
3. Optionally add a small top inset so the first line is not pressed against
   the navigation bar.

## Related

- `docs/tasks/01-editor-font-config.md` (also touches editor appearance)
