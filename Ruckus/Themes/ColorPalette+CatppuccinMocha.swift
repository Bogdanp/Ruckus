import UIKit

extension ColorPalette {
  static let catppuccinMocha = ColorPalette(
    backgroundColor: UIColor(hex: 0x1E1E2E),
    textColor: UIColor(hex: 0xCDD6F4),
    gutterBackground: UIColor(hex: 0x181825),
    gutterHairline: UIColor(hex: 0x313244),
    lineNumber: UIColor(hex: 0x585B70),
    selectedLineBackground: UIColor(hex: 0x313244),
    selectedLinesLineNumber: UIColor(hex: 0xCDD6F4),
    selectedLinesGutterBackground: UIColor(hex: 0x313244),
    invisibleCharacters: UIColor(hex: 0x585B70, alpha: 0.5),
    markedTextBackground: UIColor(hex: 0x45475A, alpha: 0.5),
    syntaxColors: [
      Highlight.comment: UIColor(hex: 0x6C7086),
      Highlight.string: UIColor(hex: 0xA6E3A1),
      Highlight.stringSpecial: UIColor(hex: 0xA6E3A1),
      Highlight.escape: UIColor(hex: 0xF2CDCD),
      Highlight.number: UIColor(hex: 0xFAB387),
      Highlight.constant: UIColor(hex: 0xFAB387),
      Highlight.constantBuiltin: UIColor(hex: 0xFAB387),
      Highlight.keyword: UIColor(hex: 0xCBA6F7),
      Highlight.variable: UIColor(hex: 0xCDD6F4),
      Highlight.variableBuiltin: UIColor(hex: 0xF38BA8),
      Highlight.variableParameter: UIColor(hex: 0xEBA0AC),
      Highlight.function: UIColor(hex: 0x89B4FA),
      Highlight.functionBuiltin: UIColor(hex: 0x74C7EC),
      Highlight.operator: UIColor(hex: 0x89DCEB),
      Highlight.punctuationBracket: UIColor(hex: 0x9399B2)
    ],
    boldNames: [Highlight.keyword]
  )
}
