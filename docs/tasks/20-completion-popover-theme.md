# Make completion popover match the current theme

## Summary

The completion popover uses hardcoded system colors (`secondarySystemBackground`,
`UIColor.label`, `UIColor.systemBlue`) regardless of which editor theme is
selected. When a user picks a dark theme like Monokai or Dracula, the popover
still renders with default system styling, creating a visual mismatch.

## Affected Code

### `Ruckus/Views/CompletionPopover.swift:18-23`

```swift
backgroundColor = .secondarySystemBackground
layer.cornerRadius = 8
layer.shadowColor = UIColor.black.cgColor
layer.shadowOpacity = 0.2
layer.shadowOffset = CGSize(width: 0, height: 2)
layer.shadowRadius = 4
```

Background is hardcoded to system secondary background.

### `Ruckus/Views/CompletionPopover.swift:85-92`

```swift
let attributed = NSMutableAttributedString(
  string: item,
  attributes: [.font: completionFont, .foregroundColor: UIColor.label]
)
let matchRange = NSRange(location: 0, length: (prefix as NSString).length)
attributed.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: matchRange)
cell.textLabel?.attributedText = attributed
cell.backgroundColor = .clear
```

Text color (`UIColor.label`) and matched-prefix highlight (`UIColor.systemBlue`)
are both hardcoded system colors.

### `Ruckus/Views/CodeEditingView.swift:53`

The popover is created in the `Coordinator` without any palette reference.

## Impact

The completion popover clashes visually with non-system themes. Light themes
like GitHub Light or Solarized Light are less affected since system colors
happen to be close, but dark themes like Catppuccin Mocha, Dracula, or Monokai
show an obvious mismatch.

## Suggested Fix

Add a `ColorPalette?` parameter to `CompletionPopover` (or an `updatePalette`
method alongside the existing `updateFont`). Map palette colors as follows:

- **Background**: `palette?.gutterBackground ?? .secondarySystemBackground`
  (matches the gutter, giving a subtle contrast against the editor background)
- **Text color**: `palette?.textColor ?? .label`
- **Matched prefix**: `palette?.syntaxColors[Highlight.keyword] ?? .systemBlue`
  (reuse the keyword color for the typed prefix highlight — it's visually
  prominent in every theme)

Then in `CodeEditingView.Coordinator`, call `updatePalette` alongside the
existing `updateFont` whenever the theme changes.

Alternatively, a new `completionBackground` / `completionHighlight` pair could
be added to `ColorPalette`, but that requires updating every theme definition
for minimal benefit — reusing existing palette colors is simpler.

## Related

- None.
