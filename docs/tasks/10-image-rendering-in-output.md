# Render images and plots in output

## Summary

The output pane only displays text (stdout/stderr as `NSAttributedString`).
Racket's `racket/draw` and `plot/no-gui` libraries can produce bitmaps, but
the output pane has no way to render them. Note: GUI-dependent libraries like
`2htdp/image`, `pict`, and the default `plot` function likely do not work on
iOS since they depend on `racket/gui`.

## Affected Code

### `Ruckus/Models/EditorDocument.swift:31-48`

```swift
func appendOutput(_ text: String, stream: Stream, font: UIFont? = nil) {
  // Builds NSAttributedString from text only
}
```

Output is text-only. No mechanism for embedding images.

### `Ruckus/Views/OutputSheetView.swift:14-41`

The output view uses a `UITextView` which supports `NSTextAttachment` for
inline images, but nothing currently produces image data.

### `ruckus-core/executor.rkt`

The executor captures stdout/stderr as byte streams. For normal script runs it
loads the module with `namespace-require` and returns exported symbols, not the
module's final value, so returned bitmaps are not observable today.

## Impact

Users cannot use Racket's rich graphical libraries. Plot and image output is
either invisible or produces unreadable binary data in the text output.

## Suggested Fix

1. **Define an explicit image-emission path** — do not rely on the module
   evaluation result for ordinary `.rkt` execution. Extend the executor with
   a dedicated mechanism for scripts to emit image data, such as a special
   output channel, a registered callback, or a helper API that accepts a
   `bitmap%` and serializes it to PNG bytes via `send bitmap save-file`.
   Note: GUI-dependent libraries like `2htdp/image` and the default `plot`
   function may not work on iOS. Use `plot-bitmap` or `plot-file` from
   `plot/no-gui` instead, and `racket/draw` primitives for image
   construction.
2. **New execution step type** — extend `ExecutionStep`/`ExecutionOutput` to
   include an image variant (PNG data).
3. **Display in output view** — use `NSTextAttachment` to embed images inline
   in the `NSAttributedString` output, or display them in a dedicated image
   view below the text.
4. **Fallback** — for unsupported image types, print a placeholder message.

## Related

- Task 09: Execution history — history storage needs to accommodate image
  data if this feature is implemented.
