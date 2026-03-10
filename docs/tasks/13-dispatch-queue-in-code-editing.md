# Replace DispatchQueue.main.async With SwiftUI Lifecycle in CodeEditingView

## Summary

`CodeEditingView.makeUIView()` uses `DispatchQueue.main.async` to defer
adding the completion popover to the window and capturing the undo manager.
This is a UIKit escape hatch inside a SwiftUI `UIViewRepresentable` — it
works, but it bypasses SwiftUI's lifecycle and can cause timing issues (e.g.
`textView.window` may still be nil on the next run loop tick in some
scenarios).

## Affected Code

### `CodeEditingView.swift:53-56`

```swift
DispatchQueue.main.async {
  textView.window?.addSubview(popover)
  textViewUndoManager = textView.undoManager
}
```

The popover is added directly to the window as a sibling of the SwiftUI
view hierarchy. The undo manager binding is set in a dispatch block rather
than through SwiftUI's update cycle.

## Impact

- If `textView.window` is nil when the dispatch fires, the popover is never
  added and completions silently stop working.
- Setting a `@Binding` from `DispatchQueue.main.async` rather than from
  `updateUIView` is fragile — SwiftUI may not pick up the change in all
  cases.

## Suggested Fix

Move undo manager capture to `updateUIView`, which is called after the view
is in the hierarchy:

```swift
func updateUIView(_ textView: TextView, context: Context) {
  ...
  if textViewUndoManager !== textView.undoManager {
    textViewUndoManager = textView.undoManager
  }
}
```

For the popover, add it in `updateUIView` with a guard to avoid re-adding:

```swift
func updateUIView(_ textView: TextView, context: Context) {
  ...
  if let popover = context.coordinator.popover,
     popover.superview == nil,
     let window = textView.window {
    window.addSubview(popover)
  }
}
```

This ensures the window exists before adding the popover and follows
SwiftUI's expected lifecycle.

## Related

- None.
