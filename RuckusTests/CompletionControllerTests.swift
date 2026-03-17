import Testing
import UIKit

@testable import Ruckus

@Suite
@MainActor
struct CompletionControllerTests {

  private let controller = CompletionController()

  // MARK: - scanIdentifiers

  @Test func emptyString() {
    let ids = controller.scanIdentifiers(in: "")
    #expect(ids.isEmpty)
  }

  @Test func singleShortToken() {
    let ids = controller.scanIdentifiers(in: "x")
    #expect(ids.isEmpty)
  }

  @Test func singleValidToken() {
    let ids = controller.scanIdentifiers(in: "foo")
    #expect(ids == ["foo"])
  }

  @Test func multipleTokens() {
    let ids = controller.scanIdentifiers(in: "(define my-helper 42)")
    #expect(ids.contains("define"))
    #expect(ids.contains("my-helper"))
    #expect(ids.contains("42"))
    #expect(!ids.contains("("))
    #expect(!ids.contains(")"))
  }

  @Test func tokenAtEndOfString() {
    let ids = controller.scanIdentifiers(in: "(add1")
    #expect(ids.contains("add1"))
  }

  @Test func filtersOutSingleCharTokens() {
    let ids = controller.scanIdentifiers(in: "(+ x y)")
    #expect(ids.isEmpty)
  }

  @Test func racketSpecialChars() {
    let ids = controller.scanIdentifiers(in: "string->number list? set!")
    #expect(ids.contains("string->number"))
    #expect(ids.contains("list?"))
    #expect(ids.contains("set!"))
  }

  @Test func deduplicates() {
    let ids = controller.scanIdentifiers(in: "(define foo (+ foo bar))")
    #expect(ids.contains("foo"))
    #expect(ids.contains("bar"))
    #expect(ids.contains("define"))
  }

  @Test func multilineText() {
    let text = """
      #lang racket/base
      (define helper 10)
      (println helper)
      """
    let ids = controller.scanIdentifiers(in: text)
    #expect(ids.contains("lang"))
    #expect(ids.contains("racket/base"))
    #expect(ids.contains("define"))
    #expect(ids.contains("helper"))
    #expect(ids.contains("println"))
    #expect(ids.contains("10"))
  }

  @Test func onlyDelimiters() {
    let ids = controller.scanIdentifiers(in: "()[]  \n\t")
    #expect(ids.isEmpty)
  }

  // MARK: - setPopover / tearDown

  @Test func setPopoverStoresPopover() {
    let ctrl = CompletionController()
    let popover = CompletionPopover { _ in }
    ctrl.setPopover(popover)
    #expect(ctrl.popover === popover)
  }

  @Test func tearDownRemovesPopover() {
    let ctrl = CompletionController()
    let popover = CompletionPopover { _ in }
    ctrl.setPopover(popover)
    ctrl.tearDown()
    #expect(ctrl.popover == nil)
  }

  // MARK: - dismiss

  @Test func dismissHidesPopover() {
    let ctrl = CompletionController()
    let popover = CompletionPopover { _ in }
    ctrl.setPopover(popover)
    popover.update(items: ["define"], prefix: "d")
    #expect(!popover.isHidden)

    ctrl.dismiss()
    #expect(popover.isHidden)
  }

  // MARK: - updatePalette

  @Test func updatePaletteDelegatesToPopover() {
    let ctrl = CompletionController()
    let popover = CompletionPopover { _ in }
    ctrl.setPopover(popover)
    ctrl.updatePalette(.dracula)
    #expect(popover.backgroundColor == ColorPalette.dracula.gutterBackground)
  }

  // MARK: - attachIfNeeded

  @Test func attachIfNeededAddsPopoverToWindow() {
    let ctrl = CompletionController()
    let popover = CompletionPopover { _ in }
    ctrl.setPopover(popover)

    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
      return
    }
    let window = UIWindow(windowScene: scene)
    ctrl.attachIfNeeded(to: window)
    #expect(popover.superview === window)
  }

  @Test func attachIfNeededSkipsWhenAlreadyAttached() {
    let ctrl = CompletionController()
    let popover = CompletionPopover { _ in }
    ctrl.setPopover(popover)

    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
      return
    }
    let window = UIWindow(windowScene: scene)
    ctrl.attachIfNeeded(to: window)
    let subviewCount = window.subviews.count
    ctrl.attachIfNeeded(to: window)
    #expect(window.subviews.count == subviewCount)
  }
}
