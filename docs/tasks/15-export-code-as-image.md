# Export code as image or PDF

## Summary

There is no way to export a script as a syntax-highlighted image or PDF for
sharing in presentations, documentation, or social media.

## Affected Code

### `Ruckus/ViewModifiers/ShareAction.swift`

The existing share action exports the raw `.rkt` file. It does not produce
a rendered/formatted version.

## Impact

Users who want to share code snippets visually must use external tools or
take screenshots manually.

## Suggested Fix

1. **Render to image** — use the existing `EditorTheme` and tree-sitter
   highlighting to render the code into a `UIImage` via an offscreen
   `UITextView` or Core Text layout. Include line numbers and a background.
2. **Share sheet integration** — add a "Share as Image" option alongside the
   existing "Share" action in the title menu.
3. **PDF export** — use `UIGraphicsPDFRenderer` to produce a PDF with
   selectable text and syntax highlighting.
4. **Customization** — let users choose background color (e.g. transparent,
   dark, light) and whether to include line numbers.

## Related

- Task 17: Share output as image — shares the same rendering and share-sheet
  infrastructure.
