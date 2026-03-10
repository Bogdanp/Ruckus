# Add an iPad target

## Summary

Ruckus currently targets only iPhone (`.iOS` destinations with no iPad
support). The app should also run natively on iPad, taking advantage of the
larger screen for a better editing experience.

## Affected Code

### `Project.swift:17-19`

```swift
.target(
  name: "Ruckus",
  destinations: .iOS,
```

The main app target uses `.iOS` which maps to iPhone only. This needs to
include iPad as a destination.

### `Project.swift:91-93`

```swift
.target(
  name: "RuckusWidgets",
  destinations: .iOS,
```

The widgets extension also targets iPhone only and should match the main
app's destinations.

### `Project.swift:115-117`

```swift
.target(
  name: "RuckusTests",
  destinations: .iOS,
```

Tests should support the same destinations as the main target.

### `Project.swift:126-129`

```swift
.target(
  name: "TreeSitterRacket",
  destinations: .iOS,
```

The TreeSitterRacket library should also support iPad.

## Impact

The app cannot be installed on iPad. Users with iPads — a natural fit for a
code editor — are excluded entirely.

## Suggested Fix

1. **Change destinations** in `Project.swift` from `.iOS` to
   `[.iPhone, .iPad]` (or the Tuist equivalent that includes both) on all
   four targets.

2. **UI review.** The current UI uses no iPad-specific layout (no
   `NavigationSplitView`, no `horizontalSizeClass` checks). On iPad the
   single-column phone layout will work but may look sparse. Consider adding
   a split-view layout (file list + editor) as a follow-up, but the initial
   target addition doesn't require it — SwiftUI will scale the existing views.

3. **Racket binaries.** Verify the bundled Racket runtime in `Ruckus/racket`
   includes arm64 slices compatible with iPadOS. If the binaries are
   universal or already arm64, no changes are needed.

## Related

- None
