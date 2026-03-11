import UIKit

@MainActor @Observable
final class EditorSettings {
  private static let fontSizeKey = "editorFontSize"
  private static let fontNameKey = "editorFontName"
  private static let themeNameKey = "editorThemeName"

  var fontSize: CGFloat {
    didSet { UserDefaults.standard.set(fontSize, forKey: Self.fontSizeKey) }
  }

  /// Empty string means system monospaced font.
  var fontName: String {
    didSet { UserDefaults.standard.set(fontName, forKey: Self.fontNameKey) }
  }

  var themeName: ColorThemeName {
    didSet { UserDefaults.standard.set(themeName.rawValue, forKey: Self.themeNameKey) }
  }

  var colorPalette: ColorPalette? { themeName.palette }

  var font: UIFont {
    if fontName.isEmpty {
      return .monospacedSystemFont(ofSize: fontSize, weight: .regular)
    }
    if let descriptor = UIFontDescriptor(name: fontName, size: fontSize).withDesign(.monospaced) {
      return UIFont(descriptor: descriptor, size: fontSize)
    }
    return UIFont(name: fontName, size: fontSize)
      ?? .monospacedSystemFont(ofSize: fontSize, weight: .regular)
  }

  static let shared = EditorSettings()

  init() {
    let defaults = UserDefaults.standard
    let storedSize = defaults.double(forKey: Self.fontSizeKey)
    self.fontSize = storedSize > 0 ? storedSize : 14
    self.fontName = defaults.string(forKey: Self.fontNameKey) ?? ""
    let storedTheme = defaults.string(forKey: Self.themeNameKey) ?? ""
    self.themeName = ColorThemeName(rawValue: storedTheme) ?? .system
  }

  static var monospaceFamilies: [String] {
    UIFont.familyNames.sorted().filter { family in
      let font = UIFont(name: UIFont.fontNames(forFamilyName: family).first ?? "", size: 14)
      return font?.fontDescriptor.symbolicTraits.contains(.traitMonoSpace) == true
    }
  }
}
