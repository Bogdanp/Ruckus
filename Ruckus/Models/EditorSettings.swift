import UIKit

@Observable
final class EditorSettings {
  private static let fontSizeKey = "editorFontSize"
  private static let fontNameKey = "editorFontName"

  var fontSize: CGFloat {
    didSet { UserDefaults.standard.set(fontSize, forKey: Self.fontSizeKey) }
  }

  /// Empty string means system monospaced font.
  var fontName: String {
    didSet { UserDefaults.standard.set(fontName, forKey: Self.fontNameKey) }
  }

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

  init() {
    let defaults = UserDefaults.standard
    let storedSize = defaults.double(forKey: Self.fontSizeKey)
    self.fontSize = storedSize > 0 ? storedSize : 14
    self.fontName = defaults.string(forKey: Self.fontNameKey) ?? ""
  }

  static var monospaceFamilies: [String] {
    UIFont.familyNames.sorted().filter { family in
      let font = UIFont(name: UIFont.fontNames(forFamilyName: family).first ?? "", size: 14)
      return font?.fontDescriptor.symbolicTraits.contains(.traitMonoSpace) == true
    }
  }
}
