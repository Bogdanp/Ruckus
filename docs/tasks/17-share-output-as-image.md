# Share output as image

## Summary

Script output can be viewed in the output sheet but cannot be shared as a
formatted image. Users must take screenshots to share output.

## Affected Code

### `Ruckus/Views/OutputSheetView.swift`

The output sheet displays an `NSAttributedString` in a `UITextView` but has
no share/export functionality.

### `Ruckus/Views/ContentView.swift:154-161`

The output toolbar button only opens the sheet — no share action.

## Impact

Sharing script results (e.g. for teaching, debugging, or social media)
requires manual screenshots with no control over framing or formatting.

## Suggested Fix

1. **Add share button to OutputSheetView** — place a share icon in the sheet's
   navigation bar.
2. **Render to image** — snapshot the `UITextView` content as a `UIImage`
   using `UIGraphicsImageRenderer`, including the colored stdout/stderr text.
3. **Include metadata** — optionally overlay the script name and timestamp.
4. **Share sheet** — present `UIActivityViewController` with the rendered
   image.

## Related

- Task 15: Export code as image — shares the same rendering and share-sheet
  infrastructure.
