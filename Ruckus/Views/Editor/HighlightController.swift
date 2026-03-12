import Runestone
import UIKit

@MainActor
final class HighlightController {
  private(set) var rainbowEnabled: Bool = false
  private(set) var rainbowColors: [UIColor] = BracketHighlighter.defaultColors
  private(set) var matchColor: UIColor = BracketHighlighter.matchColor
  private let bracketHighlighter = BracketHighlighter()

  private var cachedRainbowRanges: [HighlightedRange] = []
  private var cachedMatchRanges: [HighlightedRange] = []
  private weak var flashView: UIView?
  private var lastMatchedPosition: Int?

  func applyColors(from settings: EditorSettings) {
    rainbowEnabled = settings.rainbowParentheses
    if let palette = settings.colorPalette {
      rainbowColors = palette.rainbowColors
      matchColor = palette.matchHighlightColor
    } else {
      rainbowColors = BracketHighlighter.defaultColors
      matchColor = BracketHighlighter.matchColor
    }
  }

  func updateBracketHighlights(in textView: TextView) {
    updateBracketHighlights(text: textView.text, in: textView)
  }

  func updateBracketHighlights(text: String, in textView: TextView) {
    guard rainbowEnabled else {
      cachedRainbowRanges = []
      textView.highlightedRanges = cachedMatchRanges
      return
    }
    cachedRainbowRanges = bracketHighlighter.highlightedRanges(
      in: text, colors: rainbowColors
    )
    textView.highlightedRanges = cachedRainbowRanges + cachedMatchRanges
  }

  func updateMatchHighlight(in textView: TextView) {
    guard let selectedRange = textView.selectedTextRange else {
      applyMatchRanges([], to: textView)
      return
    }
    let cursorPos = textView.offset(
      from: textView.beginningOfDocument, to: selectedRange.start
    )
    guard let match = bracketHighlighter.findMatch(in: textView.text, at: cursorPos) else {
      applyMatchRanges([], to: textView)
      return
    }

    let cursorOnOpen = (cursorPos == match.open + 1) || (cursorPos == match.open)
    let otherPosition = cursorOnOpen ? match.close : match.open

    let ranges = [
      HighlightedRange(
        range: NSRange(location: otherPosition, length: 1),
        color: matchColor,
        cornerRadius: 2
      )
    ]
    applyMatchRanges(ranges, to: textView)

    if otherPosition != lastMatchedPosition {
      lastMatchedPosition = otherPosition
      flashMatchingBracket(at: otherPosition, in: textView)
    }
  }

  func clearMatchState() {
    lastMatchedPosition = nil
  }

  private func applyMatchRanges(_ ranges: [HighlightedRange], to textView: TextView) {
    if ranges.isEmpty { lastMatchedPosition = nil }
    cachedMatchRanges = ranges
    textView.highlightedRanges = cachedRainbowRanges + ranges
  }

  private func flashMatchingBracket(at position: Int, in textView: TextView) {
    flashView?.layer.removeAllAnimations()
    flashView?.removeFromSuperview()

    guard let start = textView.position(from: textView.beginningOfDocument, offset: position),
          let end = textView.position(from: start, offset: 1),
          let textRange = textView.textRange(from: start, to: end)
    else { return }

    let rects = textView.selectionRects(for: textRange)
    guard let firstRect = rects.first else { return }
    let charRect = firstRect.rect
    guard !charRect.isEmpty else { return }

    let flash = UIView(frame: charRect.insetBy(dx: -1, dy: -1))
    flash.backgroundColor = matchColor.withAlphaComponent(0.8)
    flash.layer.cornerRadius = 3
    flash.isUserInteractionEnabled = false
    textView.addSubview(flash)
    self.flashView = flash

    UIView.animate(withDuration: 0.3, delay: 0.5, options: .curveEaseOut) {
      flash.alpha = 0
    } completion: { [weak flash] _ in
      flash?.removeFromSuperview()
    }
  }
}
