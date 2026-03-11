import Runestone
import UIKit

struct ColorPalette {
  let backgroundColor: UIColor
  let textColor: UIColor
  let gutterBackground: UIColor
  let gutterHairline: UIColor
  let lineNumber: UIColor
  let selectedLineBackground: UIColor
  let selectedLinesLineNumber: UIColor
  let selectedLinesGutterBackground: UIColor
  let invisibleCharacters: UIColor
  let markedTextBackground: UIColor
  let syntaxColors: [String: UIColor]
  let boldNames: Set<String>

  func syntaxColor(for name: String) -> UIColor? {
    syntaxColors[name]
  }

  func fontTraits(for name: String) -> FontTraits {
    boldNames.contains(name) ? .bold : []
  }

  enum Highlight {
    static let comment = "comment"
    static let string = "string"
    static let stringSpecial = "string.special"
    static let escape = "escape"
    static let number = "number"
    static let constant = "constant"
    static let constantBuiltin = "constant.builtin"
    static let keyword = "keyword"
    static let variable = "variable"
    static let variableBuiltin = "variable.builtin"
    static let variableParameter = "variable.parameter"
    static let function = "function"
    static let functionBuiltin = "function.builtin"
    static let `operator` = "operator"
    static let punctuationBracket = "punctuation.bracket"
  }
}
