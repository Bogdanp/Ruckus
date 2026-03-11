import UIKit

extension ColorPalette {
  static let gitHubLight = ColorPalette(
    backgroundColor: UIColor(hex: 0xFFFFFF),
    textColor: UIColor(hex: 0x1F2328),
    gutterBackground: UIColor(hex: 0xF6F8FA),
    gutterHairline: UIColor(hex: 0xD1D9E0),
    lineNumber: UIColor(hex: 0x8C959F),
    selectedLineBackground: UIColor(hex: 0xFFF8C5),
    selectedLinesLineNumber: UIColor(hex: 0x1F2328),
    selectedLinesGutterBackground: UIColor(hex: 0xFFF8C5),
    invisibleCharacters: UIColor(hex: 0x8C959F, alpha: 0.5),
    markedTextBackground: UIColor(hex: 0xDDF4FF, alpha: 0.7),
    syntaxColors: [
      Highlight.comment: UIColor(hex: 0x59636E),
      Highlight.string: UIColor(hex: 0x0A3069),
      Highlight.stringSpecial: UIColor(hex: 0x0A3069),
      Highlight.escape: UIColor(hex: 0x0550AE),
      Highlight.number: UIColor(hex: 0x0550AE),
      Highlight.constant: UIColor(hex: 0x0550AE),
      Highlight.constantBuiltin: UIColor(hex: 0x0550AE),
      Highlight.keyword: UIColor(hex: 0xCF222E),
      Highlight.variable: UIColor(hex: 0x1F2328),
      Highlight.variableBuiltin: UIColor(hex: 0x953800),
      Highlight.variableParameter: UIColor(hex: 0x953800),
      Highlight.function: UIColor(hex: 0x6639BA),
      Highlight.functionBuiltin: UIColor(hex: 0x6639BA),
      Highlight.operator: UIColor(hex: 0xCF222E),
      Highlight.punctuationBracket: UIColor(hex: 0x1F2328)
    ],
    boldNames: [Highlight.keyword]
  )
}
