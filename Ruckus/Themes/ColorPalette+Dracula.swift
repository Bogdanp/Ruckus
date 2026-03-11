import UIKit

extension ColorPalette {
  static let dracula = ColorPalette(
    backgroundColor: UIColor(hex: 0x282A36),
    textColor: UIColor(hex: 0xF8F8F2),
    gutterBackground: UIColor(hex: 0x21222C),
    gutterHairline: UIColor(hex: 0x44475A),
    lineNumber: UIColor(hex: 0x6272A4),
    selectedLineBackground: UIColor(hex: 0x44475A),
    selectedLinesLineNumber: UIColor(hex: 0xF8F8F2),
    selectedLinesGutterBackground: UIColor(hex: 0x44475A),
    invisibleCharacters: UIColor(hex: 0x6272A4, alpha: 0.5),
    markedTextBackground: UIColor(hex: 0x44475A, alpha: 0.5),
    syntaxColors: [
      Highlight.comment: UIColor(hex: 0x6272A4),
      Highlight.string: UIColor(hex: 0xF1FA8C),
      Highlight.stringSpecial: UIColor(hex: 0xF1FA8C),
      Highlight.escape: UIColor(hex: 0xFF79C6),
      Highlight.number: UIColor(hex: 0xBD93F9),
      Highlight.constant: UIColor(hex: 0xBD93F9),
      Highlight.constantBuiltin: UIColor(hex: 0xBD93F9),
      Highlight.keyword: UIColor(hex: 0xFF79C6),
      Highlight.variable: UIColor(hex: 0xF8F8F2),
      Highlight.variableBuiltin: UIColor(hex: 0x8BE9FD),
      Highlight.variableParameter: UIColor(hex: 0xFFB86C),
      Highlight.function: UIColor(hex: 0x50FA7B),
      Highlight.functionBuiltin: UIColor(hex: 0x8BE9FD),
      Highlight.operator: UIColor(hex: 0xFF79C6),
      Highlight.punctuationBracket: UIColor(hex: 0xF8F8F2)
    ],
    boldNames: [Highlight.keyword]
  )
}
