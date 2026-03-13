import Runestone
import UIKit

@MainActor
final class CompletionController {
  var allCompletions: [String] = []
  private(set) var popover: CompletionPopover?

  private static let wordChars = CharacterSet.alphanumerics
    .union(CharacterSet(charactersIn: "-_!?*/+<>="))

  func setPopover(_ popover: CompletionPopover?) {
    self.popover = popover
  }

  func dismiss() {
    popover?.dismiss()
  }

  func updateFont(_ font: UIFont) {
    popover?.updateFont(font)
  }

  func updatePalette(_ palette: ColorPalette?) {
    popover?.updatePalette(palette)
  }

  func attachIfNeeded(to window: UIWindow) {
    guard let popover, popover.superview == nil else { return }
    window.addSubview(popover)
  }

  func tearDown() {
    popover?.removeFromSuperview()
    popover = nil
  }

  func updatePopover(text: String, for textView: TextView) {
    guard let popover else { return }
    let prefix = currentWordPrefix(text: text, in: textView)
    let filtered: [String]
    if prefix.isEmpty {
      filtered = []
    } else {
      filtered = allCompletions.filter {
        $0.hasPrefix(prefix) && $0 != prefix
      }
    }
    guard !filtered.isEmpty else {
      popover.dismiss()
      return
    }
    popover.update(items: Array(filtered.prefix(20)), prefix: prefix)
    positionPopover(popover, in: textView)
  }

  private func positionPopover(
    _ popover: CompletionPopover, in textView: TextView
  ) {
    guard let selectedRange = textView.selectedTextRange,
          let window = textView.window
    else { return }
    let caretRect = textView.caretRect(for: selectedRange.start)
    let caretInWindow = textView.convert(caretRect, to: window)
    let originX = caretInWindow.maxX + 2
    let originY = caretInWindow.minY
    let availableWidth = window.bounds.width - originX
    popover.frame.origin = CGPoint(x: originX, y: max(4, originY))
    popover.frame.size.width = min(popover.frame.width, max(0, availableWidth))
  }

  private func currentWordPrefix(text: String, in textView: TextView) -> String {
    guard let selectedRange = textView.selectedTextRange else { return "" }
    let cursorPos = textView.offset(
      from: textView.beginningOfDocument, to: selectedRange.start
    )
    guard cursorPos >= 0 else { return "" }
    let idx = text.index(
      text.startIndex, offsetBy: min(cursorPos, text.count)
    )
    var start = idx
    while start > text.startIndex {
      let prev = text.index(before: start)
      guard let scalar = text[prev].unicodeScalars.first,
            Self.wordChars.contains(scalar) else { break }
      start = prev
    }
    let prefix = String(text[start..<idx])
    return prefix.count >= 2 ? prefix : ""
  }
}
