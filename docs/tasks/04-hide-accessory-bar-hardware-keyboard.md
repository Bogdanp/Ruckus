# Hide accessory bar when a hardware keyboard is attached

## Summary

The editor always shows a two-row symbol accessory bar above the keyboard,
even when a Magic Keyboard (or other hardware keyboard) is attached on iPad.
With a hardware keyboard every symbol in the bar is directly typeable, so the
bar wastes vertical space and looks out of place floating above the bottom
edge of the screen.

## Affected Code

### `CodeEditingView.swift:30-32`

```swift
textView.inputAccessoryView = EditorAccessoryBar.makeInputAccessoryView(
  for: textView, palette: settings.colorPalette
)
```

The accessory view is assigned unconditionally in `makeUIView`. There is no
check for whether a hardware keyboard is connected.

### `CodeEditingView.swift:108-111`

```swift
textView.inputAccessoryView = EditorAccessoryBar.makeInputAccessoryView(
  for: textView, palette: settings.colorPalette
)
textView.reloadInputViews()
```

Same unconditional assignment in `updateUIView` when the theme changes.

## Impact

On iPad with a Magic Keyboard, the accessory bar appears as a 76pt-tall strip
at the bottom of the screen (the software keyboard is hidden). It takes up
space that could be used by the editor and provides no value since all symbols
are available on the physical keyboard.

## Suggested Fix

Use `GCKeyboard.coalesced` (GameController framework) or
`UIApplication.shared.connectedScenes` trait collection checks to detect
hardware keyboard presence, and set `inputAccessoryView` to `nil` when one is
attached.

The recommended approach on iOS 17+ is to observe
`UITraitCollection.keyboardAppearance` or use
`NotificationCenter` with keyboard show/hide notifications: when a hardware
keyboard is connected, `UIResponder.keyboardWillShowNotification` is not
posted (or the keyboard frame is off-screen), so the accessory bar can be
hidden.

A simpler heuristic: listen to `keyboardWillShowNotification` /
`keyboardWillHideNotification`. When the keyboard hides (hardware keyboard
attached), set `inputAccessoryView = nil` and `reloadInputViews()`. When the
software keyboard appears, re-attach the accessory bar.

```swift
// In Coordinator or a helper:
func observeKeyboard(for textView: TextView, palette: ColorPalette?) {
  NotificationCenter.default.addObserver(
    forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main
  ) { _ in
    if textView.inputAccessoryView == nil {
      textView.inputAccessoryView = EditorAccessoryBar.makeInputAccessoryView(
        for: textView, palette: palette
      )
      textView.reloadInputViews()
    }
  }
  NotificationCenter.default.addObserver(
    forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main
  ) { _ in
    textView.inputAccessoryView = nil
    textView.reloadInputViews()
  }
}
```

**Alternative**: Check `traitCollection.userInterfaceIdiom == .pad` and
`GCKeyboard.coalesced != nil` for a more direct hardware-keyboard check, but
this requires importing GameController.

## Related

- `docs/tasks/03-ipad-menu-bar.md` — related iPad keyboard experience
  improvement.
