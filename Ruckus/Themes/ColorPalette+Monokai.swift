import UIKit

extension ColorPalette {
  static let monokai = ColorPalette(
    backgroundColor: UIColor(hex: 0x272822),
    textColor: UIColor(hex: 0xF8F8F2),
    gutterBackground: UIColor(hex: 0x222218),
    gutterHairline: UIColor(hex: 0x33332E),
    lineNumber: UIColor(hex: 0x8C8C80),
    selectedLineBackground: UIColor(hex: 0x33332E),
    selectedLinesLineNumber: UIColor(hex: 0xF8F8F2),
    selectedLinesGutterBackground: UIColor(hex: 0x33332E),
    invisibleCharacters: UIColor(hex: 0x595954),
    markedTextBackground: UIColor(hex: 0x40403B, alpha: 0.5),
    matchHighlightColor: UIColor(hex: 0xE6DB74, alpha: 0.5),
    rainbowColors: [
      UIColor(hex: 0xF92672, alpha: 0.15),
      UIColor(hex: 0xFD971F, alpha: 0.15),
      UIColor(hex: 0xE6DB74, alpha: 0.15),
      UIColor(hex: 0xA6E22E, alpha: 0.15),
      UIColor(hex: 0x66DAEE, alpha: 0.15),
      UIColor(hex: 0xAE81FF, alpha: 0.15)
    ],
    syntaxColors: [
      Highlight.comment: UIColor(hex: 0x75715E),
      Highlight.string: UIColor(hex: 0xE6DB74),
      Highlight.stringSpecial: UIColor(hex: 0xE6DB74),
      Highlight.escape: UIColor(hex: 0xAE81FF),
      Highlight.number: UIColor(hex: 0xAE81FF),
      Highlight.constant: UIColor(hex: 0xAE81FF),
      Highlight.constantBuiltin: UIColor(hex: 0xAE81FF),
      Highlight.keyword: UIColor(hex: 0xF92672),
      Highlight.variable: UIColor(hex: 0xF8F8F2),
      Highlight.variableBuiltin: UIColor(hex: 0xFD971F),
      Highlight.variableParameter: UIColor(hex: 0xFD971F),
      Highlight.function: UIColor(hex: 0xA6E22E),
      Highlight.functionBuiltin: UIColor(hex: 0x66DAEE),
      Highlight.operator: UIColor(hex: 0xF92672),
      Highlight.punctuationBracket: UIColor(hex: 0xF8F8F2)
    ],
    boldNames: [Highlight.keyword]
  )
}
