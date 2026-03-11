import UIKit

extension ColorPalette {
  static let gruvboxDark = ColorPalette(
    backgroundColor: UIColor(hex: 0x282828),
    textColor: UIColor(hex: 0xEBDBB2),
    gutterBackground: UIColor(hex: 0x1D2021),
    gutterHairline: UIColor(hex: 0x3C3836),
    lineNumber: UIColor(hex: 0x665C54),
    selectedLineBackground: UIColor(hex: 0x3C3836),
    selectedLinesLineNumber: UIColor(hex: 0xEBDBB2),
    selectedLinesGutterBackground: UIColor(hex: 0x3C3836),
    invisibleCharacters: UIColor(hex: 0x665C54, alpha: 0.5),
    markedTextBackground: UIColor(hex: 0x504945, alpha: 0.5),
    syntaxColors: [
      Highlight.comment: UIColor(hex: 0x928374),
      Highlight.string: UIColor(hex: 0xB8BB26),
      Highlight.stringSpecial: UIColor(hex: 0xB8BB26),
      Highlight.escape: UIColor(hex: 0xFE8019),
      Highlight.number: UIColor(hex: 0xD3869B),
      Highlight.constant: UIColor(hex: 0xD3869B),
      Highlight.constantBuiltin: UIColor(hex: 0xD3869B),
      Highlight.keyword: UIColor(hex: 0xFB4934),
      Highlight.variable: UIColor(hex: 0xEBDBB2),
      Highlight.variableBuiltin: UIColor(hex: 0xFABD2F),
      Highlight.variableParameter: UIColor(hex: 0xEBDBB2),
      Highlight.function: UIColor(hex: 0x8EC07C),
      Highlight.functionBuiltin: UIColor(hex: 0x83A598),
      Highlight.operator: UIColor(hex: 0xFE8019),
      Highlight.punctuationBracket: UIColor(hex: 0xA89984)
    ],
    boldNames: [Highlight.keyword]
  )
}
