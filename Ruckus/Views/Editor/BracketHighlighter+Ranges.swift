import Runestone
import UIKit

extension BracketHighlighter {
  func highlightedRanges(
    in text: String,
    colors: [UIColor]
  ) -> [HighlightedRange] {
    guard !colors.isEmpty else { return [] }
    return findBrackets(in: text).map { bracket in
      HighlightedRange(
        range: NSRange(location: bracket.position, length: 1),
        color: colors[bracket.depth % colors.count],
        cornerRadius: 2
      )
    }
  }
}
