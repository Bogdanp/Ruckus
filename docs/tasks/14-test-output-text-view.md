# Test OutputTextView scroll anchor logic

## Summary

`OutputTextView` has 0% test coverage (70 executable lines). Its
`Coordinator` class contains scroll-anchor detection logic that keeps
the output scrolled to the bottom as new content arrives, but stops
auto-scrolling when the user manually scrolls up. This logic is
independent of SwiftUI and testable via direct `UIScrollView`
manipulation.

## Affected Code

### `Ruckus/Views/OutputTextView.swift:56-87`

```swift
final class Coordinator: NSObject, UIScrollViewDelegate {
  weak var textView: UITextView?
  var lastVersion: UInt64 = 0
  private var userHasScrolled = false

  func isAnchoredToBottom(_ scrollView: UIScrollView) -> Bool {
    if !userHasScrolled { return true }
    let bottomEdge = scrollView.contentSize.height - scrollView.bounds.height
      + scrollView.adjustedContentInset.bottom
    let threshold: CGFloat = 40
    return scrollView.contentOffset.y >= bottomEdge - threshold
  }

  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    userHasScrolled = true
  }

  // ...resetAnchorIfAtBottom...
}
```

## Impact

Regressions in anchor logic would cause the output view to either
not auto-scroll (missing new output) or force-scroll when the user is
reading earlier output.

## Suggested Fix

Add `RuckusTests/Views/OutputTextViewTests.swift` testing the
`Coordinator` directly:

1. **Anchored by default** — fresh coordinator returns `true` from
   `isAnchoredToBottom` regardless of scroll position.
2. **User drag disables anchor** — call
   `scrollViewWillBeginDragging`, verify `isAnchoredToBottom` returns
   `false` when scrolled away from bottom.
3. **Within threshold re-anchors** — after dragging, set content offset
   near the bottom (within 40pt), call `scrollViewDidEndDecelerating`,
   verify anchor resets to `true`.
4. **Beyond threshold stays unanchored** — content offset far from
   bottom, call `scrollViewDidEndDragging(willDecelerate: false)`,
   verify anchor stays `false`.
5. **Version guard prevents duplicate updates** — set `lastVersion`,
   call `updateUIView` with the same version, verify `attributedText`
   is not reassigned.

## Related

- None.
