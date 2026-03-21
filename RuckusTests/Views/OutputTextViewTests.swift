import Testing
import UIKit

@testable import Ruckus

@Suite
@MainActor
struct OutputTextViewTests {

  private func makeScrollView(
    contentHeight: CGFloat = 1000,
    boundsHeight: CGFloat = 400,
    contentOffsetY: CGFloat = 0
  ) -> UIScrollView {
    let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: boundsHeight))
    scrollView.contentSize = CGSize(width: 320, height: contentHeight)
    scrollView.contentOffset.y = contentOffsetY
    return scrollView
  }

  // MARK: - isAnchoredToBottom

  @Test
  func anchoredByDefault() {
    let coordinator = OutputTextView.Coordinator()
    let scrollView = makeScrollView(contentOffsetY: 0)
    #expect(coordinator.isAnchoredToBottom(scrollView))
  }

  @Test
  func userDragDisablesAnchor() {
    let coordinator = OutputTextView.Coordinator()
    let scrollView = makeScrollView(contentOffsetY: 0)
    coordinator.scrollViewWillBeginDragging(scrollView)
    #expect(!coordinator.isAnchoredToBottom(scrollView))
  }

  @Test
  func withinThresholdReAnchors() {
    let coordinator = OutputTextView.Coordinator()
    let scrollView = makeScrollView(contentHeight: 1000, boundsHeight: 400)
    coordinator.scrollViewWillBeginDragging(scrollView)
    scrollView.contentOffset.y = 590  // 10pt from bottom edge (600), within 40pt threshold
    coordinator.scrollViewDidEndDecelerating(scrollView)
    #expect(coordinator.isAnchoredToBottom(scrollView))
  }

  @Test
  func beyondThresholdStaysUnanchored() {
    let coordinator = OutputTextView.Coordinator()
    let scrollView = makeScrollView(contentHeight: 1000, boundsHeight: 400)
    coordinator.scrollViewWillBeginDragging(scrollView)
    scrollView.contentOffset.y = 100
    coordinator.scrollViewDidEndDragging(scrollView, willDecelerate: false)
    #expect(!coordinator.isAnchoredToBottom(scrollView))
  }

  @Test
  func willDecelerateSkipsReset() {
    let coordinator = OutputTextView.Coordinator()
    let scrollView = makeScrollView(contentHeight: 1000, boundsHeight: 400)
    coordinator.scrollViewWillBeginDragging(scrollView)
    scrollView.contentOffset.y = 590  // near bottom, would reset userHasScrolled if checked
    coordinator.scrollViewDidEndDragging(scrollView, willDecelerate: true)
    // resetAnchorIfAtBottom is NOT called when willDecelerate is true,
    // so userHasScrolled stays true — moving away from bottom should return false
    scrollView.contentOffset.y = 100
    #expect(!coordinator.isAnchoredToBottom(scrollView))
  }

  @Test
  func anchorAccountsForContentInset() {
    let coordinator = OutputTextView.Coordinator()
    let scrollView = makeScrollView(contentHeight: 1000, boundsHeight: 400)
    scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
    coordinator.scrollViewWillBeginDragging(scrollView)
    // Bottom edge = 1000 - 400 + 50 = 650; threshold = 40; need offset >= 610
    scrollView.contentOffset.y = 620
    #expect(coordinator.isAnchoredToBottom(scrollView))
  }
}
