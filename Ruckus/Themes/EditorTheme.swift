import Runestone
import UIKit

final class EditorTheme: Runestone.Theme {
  private let base = DefaultTheme()
  private let editorFont: UIFont

  var font: UIFont { editorFont }
  var textColor: UIColor { base.textColor }
  var gutterBackgroundColor: UIColor { base.gutterBackgroundColor }
  var gutterHairlineColor: UIColor { base.gutterHairlineColor }
  var lineNumberColor: UIColor { base.lineNumberColor }
  var lineNumberFont: UIFont { editorFont.withSize(editorFont.pointSize) }
  var selectedLineBackgroundColor: UIColor { base.selectedLineBackgroundColor }
  var selectedLinesLineNumberColor: UIColor { base.selectedLinesLineNumberColor }
  var selectedLinesGutterBackgroundColor: UIColor { base.selectedLinesGutterBackgroundColor }
  var invisibleCharactersColor: UIColor { base.invisibleCharactersColor }
  var pageGuideHairlineColor: UIColor { base.pageGuideHairlineColor }
  var pageGuideBackgroundColor: UIColor { base.pageGuideBackgroundColor }
  var markedTextBackgroundColor: UIColor { base.markedTextBackgroundColor }

  init(font: UIFont) {
    self.editorFont = font
  }

  func textColor(for highlightName: String) -> UIColor? {
    base.textColor(for: highlightName)
  }

  func fontTraits(for highlightName: String) -> FontTraits {
    base.fontTraits(for: highlightName)
  }

  @available(iOS 16.0, *)
  func highlightedRange(
    forFoundTextRange foundTextRange: NSRange,
    ofStyle style: UITextSearchFoundTextStyle
  ) -> HighlightedRange? {
    base.highlightedRange(forFoundTextRange: foundTextRange, ofStyle: style)
  }
}
