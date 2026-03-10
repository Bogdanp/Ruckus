# Simplify Error Alert Binding in ContentView

## Summary

ContentView creates a manual `Binding(get:set:)` to bridge an optional error
string into an `isPresented` boolean for `.alert()`. This is a common but
verbose pattern that can be simplified.

## Affected Code

### `ContentView.swift:106-113`

```swift
.alert("Share Failed", isPresented: Binding(
  get: { shareError != nil },
  set: { if !$0 { shareError = nil } }
)) {
  Button("OK", role: .cancel) {}
} message: {
  Text(shareError ?? "")
}
```

The manual `Binding` converts `shareError: String?` into a `Bool` for the
alert presentation, and clears the error on dismissal.

## Impact

Works correctly, but is unnecessarily verbose. If more error alerts are added,
this pattern would be repeated each time.

## Suggested Fix

Use a small extension on `Binding` that makes this a one-liner:

```swift
extension Optional where Wrapped == String {
  var isPresent: Bool {
    get { self != nil }
    set { if !newValue { self = nil } }
  }
}
```

Then:

```swift
.alert("Share Failed", isPresented: $shareError.isPresent) {
  Button("OK", role: .cancel) {}
} message: {
  Text(shareError ?? "")
}
```

Alternatively, use the `.alert(_:isPresented:presenting:)` overload that takes
an optional value directly — this is the SwiftUI-native way:

```swift
.alert("Share Failed", isPresented: .constant(shareError != nil), presenting: shareError) { _ in
  Button("OK", role: .cancel) { shareError = nil }
} message: { error in
  Text(error)
}
```

Either approach removes the manual Binding construction.

## Related

- Task 04 (split ContentView) — if share logic is extracted, this alert goes with it.
