# Test AsyncButtonOption set behavior

## Summary

`AsyncButtonOption` is an enum with a `Set`-based API (`all`,
`allButCancel`) that controls button behavior. The option set logic is
used throughout the codebase to configure progress, success, and
cancellation behavior, but the option sets themselves have no tests.
The existing `AsyncButtonTests` only test the `cancelsOnDisappear`
behavior.

## Affected Code

### `Views/AsyncButton.swift:3-11`

```swift
enum AsyncButtonOption: CaseIterable, Hashable {
    case cancelsOnDisappear
    case disabledWhileRunning
    case showsProgressView
    case showsSuccessIcon

    static let all = Set(Self.allCases)
    static let allButCancel = Set(Self.allCases).subtracting([.cancelsOnDisappear])
}
```

### `Views/AsyncButton.swift:32-44`

```swift
let isShowingProgress = options.contains(.showsProgressView) && loading
let isShowingSuccess = options.contains(.showsSuccessIcon) && success
// ...
.disabled(options.contains(.disabledWhileRunning) && running)
// ...
guard options.contains(.cancelsOnDisappear) else { return }
```

## Impact

Low — the enum is simple. But testing the option sets ensures the
`allButCancel` convenience set stays correct as new options are added.

## Suggested Fix

Add to `AsyncButtonTests`:

1. `AsyncButtonOption.all` contains all four cases.
2. `AsyncButtonOption.allButCancel` contains all cases except
   `.cancelsOnDisappear`.
3. `allButCancel.subtracting([.showsSuccessIcon])` produces the expected
   two-element set (used in `FolderBrowser`).

## Related

- None
