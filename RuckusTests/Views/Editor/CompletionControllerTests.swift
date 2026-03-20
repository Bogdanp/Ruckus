import Runestone
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

  // MARK: - wordPrefix

  @Test func wordPrefixAtEndOfWord() {
    let prefix = controller.wordPrefix(in: "(display", cursorOffset: 8)
    #expect(prefix == "display")
  }

  @Test func wordPrefixTooShort() {
    let prefix = controller.wordPrefix(in: "(d", cursorOffset: 2)
    #expect(prefix == "")
  }

  @Test func wordPrefixAtStartOfText() {
    let prefix = controller.wordPrefix(in: "define", cursorOffset: 0)
    #expect(prefix == "")
  }

  @Test func wordPrefixWithSpecialChars() {
    let prefix = controller.wordPrefix(in: "string->num", cursorOffset: 11)
    #expect(prefix == "string->num")
  }

  @Test func wordPrefixStopsAtDelimiter() {
    let prefix = controller.wordPrefix(in: "(define foo", cursorOffset: 11)
    #expect(prefix == "foo")
  }

  @Test func wordPrefixCursorInMiddle() {
    let prefix = controller.wordPrefix(in: "display", cursorOffset: 4)
    #expect(prefix == "disp")
  }

  @Test func wordPrefixCursorBeyondText() {
    let prefix = controller.wordPrefix(in: "ab", cursorOffset: 100)
    #expect(prefix == "ab")
  }

  // MARK: - updatePopover

  private func makeTextView(text: String) -> TextView {
    let view = TextView(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
    let theme = EditorTheme(font: .monospacedSystemFont(ofSize: 14, weight: .regular))
    let state = TextViewState(text: text, theme: theme)
    view.setState(state)

    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
      return view
    }
    let window = UIWindow(windowScene: scene)
    window.addSubview(view)
    view.frame = CGRect(x: 0, y: 0, width: 375, height: 667)
    view.layoutIfNeeded()
    return view
  }

  private func setCursor(_ textView: TextView, offset: Int) {
    if let pos = textView.position(from: textView.beginningOfDocument, offset: offset) {
      textView.selectedTextRange = textView.textRange(from: pos, to: pos)
    }
  }

  private func popoverItemCount(_ popover: CompletionPopover) -> Int {
    popover.tableView(UITableView(), numberOfRowsInSection: 0)
  }

  @Test func updatePopoverFiltersCompletions() {
    let ctrl = CompletionController()
    let popover = CompletionPopover { _ in }
    ctrl.setPopover(popover)
    ctrl.allCompletions = ["define", "display", "displayln"]

    let textView = makeTextView(text: "(dis")
    setCursor(textView, offset: 4)

    ctrl.updatePopover(text: "(dis", for: textView)

    #expect(!popover.isHidden)
    #expect(popoverItemCount(popover) == 2)
  }

  @Test func updatePopoverDismissesWhenNoMatches() {
    let ctrl = CompletionController()
    let popover = CompletionPopover { _ in }
    ctrl.setPopover(popover)
    ctrl.allCompletions = ["define", "display"]

    // Show popover first
    let textView = makeTextView(text: "(dis")
    setCursor(textView, offset: 4)
    ctrl.updatePopover(text: "(dis", for: textView)
    #expect(!popover.isHidden)

    // Now type something with no matches
    textView.text = "(xyz"
    setCursor(textView, offset: 4)
    ctrl.updatePopover(text: "(xyz", for: textView)

    #expect(popover.isHidden)
  }

  @Test func updatePopoverDeduplicates() {
    let ctrl = CompletionController()
    let popover = CompletionPopover { _ in }
    ctrl.setPopover(popover)
    // "helper" is in both allCompletions and the text
    ctrl.allCompletions = ["helper", "hello"]

    let text = "(helper-fn (hello (hel"
    let textView = makeTextView(text: text)
    setCursor(textView, offset: text.count)

    ctrl.updatePopover(text: text, for: textView)

    #expect(!popover.isHidden)
    // "hel" prefix matches: "helper" (allCompletions), "hello" (allCompletions),
    // "helper-fn" (document identifier) — 3 unique items
    #expect(popoverItemCount(popover) == 3)
  }

  @Test func updatePopoverCapsAt20() {
    let ctrl = CompletionController()
    let popover = CompletionPopover { _ in }
    ctrl.setPopover(popover)
    ctrl.allCompletions = (1...30).map { "item\($0)" }

    let textView = makeTextView(text: "(ite")
    setCursor(textView, offset: 4)

    ctrl.updatePopover(text: "(ite", for: textView)

    #expect(!popover.isHidden)
    #expect(popoverItemCount(popover) == 20)
  }
}
