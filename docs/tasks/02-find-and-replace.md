# Add find & replace to the code editor

## Summary

The code editor has no find or replace functionality. Users have no way to
search for text within a script or perform bulk replacements. Runestone's
`TextView` supports the native `UIFindInteraction` API, so enabling it should
be straightforward.

## Affected Code

### `Ruckus/Views/CodeEditingView.swift:31-54`

```swift
func makeUIView(context: Context) -> TextView {
  let textView = TextView(frame: .zero)
  // ...configuration...
  return textView
}
```

The `TextView` is created without enabling find interaction.

## Impact

Users must manually scan through code to locate text. This is especially
painful in longer scripts.

## Suggested Fix

Enable the native find interaction on the text view:

```swift
textView.isFindInteractionEnabled = true
```

This gives the standard iOS find bar (Cmd+F on hardware keyboards). No
additional UI work should be needed — UIKit provides the chrome.

Optionally, add a toolbar button or keyboard shortcut to present the find
panel programmatically via `textView.findInteraction?.presentFindNavigator`.
