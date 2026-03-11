import UIKit

extension ColorPalette {
  static let oneDark = ColorPalette(
    backgroundColor: UIColor(hex: 0x282C34),
    textColor: UIColor(hex: 0xABB2BF),
    gutterBackground: UIColor(hex: 0x23272F),
    gutterHairline: UIColor(hex: 0x383D47),
    lineNumber: UIColor(hex: 0x5C6370),
    selectedLineBackground: UIColor(hex: 0x303640),
    selectedLinesLineNumber: UIColor(hex: 0xABB2BF),
    selectedLinesGutterBackground: UIColor(hex: 0x303640),
    invisibleCharacters: UIColor(hex: 0x5C6370, alpha: 0.5),
    markedTextBackground: UIColor(hex: 0x383D47, alpha: 0.5),
    syntaxColors: [
      Highlight.comment: UIColor(hex: 0x5C6370),
      Highlight.string: UIColor(hex: 0x98C379),
      Highlight.stringSpecial: UIColor(hex: 0x98C379),
      Highlight.escape: UIColor(hex: 0x56B6C2),
      Highlight.number: UIColor(hex: 0xD19A66),
      Highlight.constant: UIColor(hex: 0xD19A66),
      Highlight.constantBuiltin: UIColor(hex: 0xD19A66),
      Highlight.keyword: UIColor(hex: 0xC678DD),
      Highlight.variable: UIColor(hex: 0xE06C75),
      Highlight.variableBuiltin: UIColor(hex: 0xE06C75),
      Highlight.variableParameter: UIColor(hex: 0xE06C75),
      Highlight.function: UIColor(hex: 0x61AFEF),
      Highlight.functionBuiltin: UIColor(hex: 0x61AFEF),
      Highlight.operator: UIColor(hex: 0x56B6C2),
      Highlight.punctuationBracket: UIColor(hex: 0xABB2BF)
    ],
    boldNames: [Highlight.keyword]
  )
}
