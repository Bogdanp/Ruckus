# Add accessibility labels to settings button and tab close button

## Summary

The Settings toolbar button and the tab close button lack accessibility labels.
The close button's tap target (16x16pt) is also below Apple's recommended
44x44pt minimum.

## Affected Code

### `Views/ContentView.swift:168-173`

The Settings gear button uses a bare `Image(systemName:)` without a label:

```swift
Button {
  activeSheet = .settings
} label: {
  Image(systemName: "gearshape")
}
```

Other toolbar buttons (Output, Run/Stop) already use
`Label(...).labelStyle(.iconOnly)` which provides VoiceOver text. The Settings
button should follow the same pattern.

### `Views/TabBar/TabBarItemContent.swift:22-29`

The close button uses a small `xmark` icon in a 16x16pt frame:

```swift
Image(systemName: "xmark")
  .font(.system(size: 8, weight: .bold))
  .foregroundColor(Color(.tertiaryLabel))
  .frame(width: 16, height: 16)
```

It has no accessibility label, and the tap target is small. The visual size is
fine but the tappable area should be enlarged with `.contentShape()` or padding.

### `Views/TabBar/TabBarItemContent.swift:17-20`

The dirty indicator circle has no accessible description:

```swift
Circle()
  .fill(isActive ? Color.accentColor : Color(.secondaryLabel))
  .frame(width: 5, height: 5)
```

## Impact

VoiceOver users cannot identify the Settings button. Users with motor
impairments may struggle with the small close button.

## Suggested Fix

1. Change the Settings button to use `Label("Settings", systemImage: "gearshape").labelStyle(.iconOnly)`.
2. Add `.accessibilityLabel("Close tab")` to the close button and enlarge
   the tappable area (e.g. padding with `.contentShape(Rectangle())`).
3. Add `.accessibilityLabel("Unsaved changes")` to the dirty indicator.
