import Runestone
import UIKit

final class EditorTheme: Runestone.Theme {
  private lazy var base = DefaultTheme()
  private let editorFont: UIFont
  private let palette: ColorPalette?

  var font: UIFont { editorFont }
  var textColor: UIColor { palette?.textColor ?? base.textColor }
  var gutterBackgroundColor: UIColor { palette?.gutterBackground ?? base.gutterBackgroundColor }
  var gutterHairlineColor: UIColor { palette?.gutterHairline ?? base.gutterHairlineColor }
  var lineNumberColor: UIColor { palette?.lineNumber ?? base.lineNumberColor }
  var lineNumberFont: UIFont { editorFont }
  var selectedLineBackgroundColor: UIColor { palette?.selectedLineBackground ?? base.selectedLineBackgroundColor }
  var selectedLinesLineNumberColor: UIColor { palette?.selectedLinesLineNumber ?? base.selectedLinesLineNumberColor }
  var selectedLinesGutterBackgroundColor: UIColor {
    palette?.selectedLinesGutterBackground ?? base.selectedLinesGutterBackgroundColor
  }
  var invisibleCharactersColor: UIColor { palette?.invisibleCharacters ?? base.invisibleCharactersColor }
  var pageGuideHairlineColor: UIColor { base.pageGuideHairlineColor }
  var pageGuideBackgroundColor: UIColor { base.pageGuideBackgroundColor }
  var markedTextBackgroundColor: UIColor { palette?.markedTextBackground ?? base.markedTextBackgroundColor }

  var backgroundColor: UIColor { palette?.backgroundColor ?? .systemBackground }

  init(font: UIFont, palette: ColorPalette? = nil) {
    self.editorFont = font
    self.palette = palette
  }

  func textColor(for highlightName: String) -> UIColor? {
    if let palette {
      return palette.syntaxColor(for: highlightName)
    }
    return base.textColor(for: highlightName)
  }

  func fontTraits(for highlightName: String) -> FontTraits {
    if let palette {
      return palette.fontTraits(for: highlightName)
    }
    return base.fontTraits(for: highlightName)
  }

  @available(iOS 16.0, *)
  func highlightedRange(
    forFoundTextRange foundTextRange: NSRange,
    ofStyle style: UITextSearchFoundTextStyle
  ) -> HighlightedRange? {
    base.highlightedRange(forFoundTextRange: foundTextRange, ofStyle: style)
  }
}
