import UIKit

extension ColorPalette {
  static let solarizedLight = ColorPalette(
    backgroundColor: UIColor(hex: 0xFDF6E3),
    textColor: UIColor(hex: 0x657B83),
    gutterBackground: UIColor(hex: 0xEEE8D5),
    gutterHairline: UIColor(hex: 0xD9D4C2),
    lineNumber: UIColor(hex: 0x93A1A1),
    selectedLineBackground: UIColor(hex: 0xEEE8D5),
    selectedLinesLineNumber: UIColor(hex: 0x657B83),
    selectedLinesGutterBackground: UIColor(hex: 0xEEE8D5),
    invisibleCharacters: UIColor(hex: 0x93A1A1, alpha: 0.5),
    markedTextBackground: UIColor(hex: 0xEEE8D5, alpha: 0.7),
    syntaxColors: [
      Highlight.comment: UIColor(hex: 0x93A1A1),
      Highlight.string: UIColor(hex: 0x2AA198),
      Highlight.stringSpecial: UIColor(hex: 0x2AA198),
      Highlight.escape: UIColor(hex: 0xCB4B16),
      Highlight.number: UIColor(hex: 0xD33682),
      Highlight.constant: UIColor(hex: 0xCB4B16),
      Highlight.constantBuiltin: UIColor(hex: 0xCB4B16),
      Highlight.keyword: UIColor(hex: 0x859900),
      Highlight.variable: UIColor(hex: 0x657B83),
      Highlight.variableBuiltin: UIColor(hex: 0x268BD2),
      Highlight.variableParameter: UIColor(hex: 0x268BD2),
      Highlight.function: UIColor(hex: 0x268BD2),
      Highlight.functionBuiltin: UIColor(hex: 0x268BD2),
      Highlight.operator: UIColor(hex: 0x859900),
      Highlight.punctuationBracket: UIColor(hex: 0x657B83)
    ],
    boldNames: [Highlight.keyword]
  )
}
