import UIKit

extension ColorPalette {
  static let nord = ColorPalette(
    backgroundColor: UIColor(hex: 0x2E3440),
    textColor: UIColor(hex: 0xD8DEE9),
    gutterBackground: UIColor(hex: 0x292E39),
    gutterHairline: UIColor(hex: 0x3B4252),
    lineNumber: UIColor(hex: 0x4C566A),
    selectedLineBackground: UIColor(hex: 0x3B4252),
    selectedLinesLineNumber: UIColor(hex: 0xD8DEE9),
    selectedLinesGutterBackground: UIColor(hex: 0x3B4252),
    invisibleCharacters: UIColor(hex: 0x4C566A, alpha: 0.5),
    markedTextBackground: UIColor(hex: 0x434C5E, alpha: 0.5),
    syntaxColors: [
      Highlight.comment: UIColor(hex: 0x616E88),
      Highlight.string: UIColor(hex: 0xA3BE8C),
      Highlight.stringSpecial: UIColor(hex: 0xA3BE8C),
      Highlight.escape: UIColor(hex: 0xEBCB8B),
      Highlight.number: UIColor(hex: 0xB48EAD),
      Highlight.constant: UIColor(hex: 0xB48EAD),
      Highlight.constantBuiltin: UIColor(hex: 0xB48EAD),
      Highlight.keyword: UIColor(hex: 0x81A1C1),
      Highlight.variable: UIColor(hex: 0xD8DEE9),
      Highlight.variableBuiltin: UIColor(hex: 0x88C0D0),
      Highlight.variableParameter: UIColor(hex: 0xD8DEE9),
      Highlight.function: UIColor(hex: 0x88C0D0),
      Highlight.functionBuiltin: UIColor(hex: 0x88C0D0),
      Highlight.operator: UIColor(hex: 0x81A1C1),
      Highlight.punctuationBracket: UIColor(hex: 0xECEFF4)
    ],
    boldNames: [Highlight.keyword]
  )
}
