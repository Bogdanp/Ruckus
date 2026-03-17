import Testing
import UIKit

@testable import Ruckus

@Suite
@MainActor
struct EditorSettingsTests {

  // MARK: - font

  @Test
  func defaultFontIsMonospaced() {
    let settings = EditorSettings()
    let font = settings.font
    #expect(font.fontDescriptor.symbolicTraits.contains(.traitMonoSpace))
  }

  @Test
  func emptyFontNameUsesSystemMonospaced() {
    let settings = EditorSettings()
    settings.fontName = ""
    settings.fontSize = 16
    let font = settings.font
    let expected = UIFont.monospacedSystemFont(ofSize: 16, weight: .regular)
    #expect(font == expected)
  }

  @Test
  func fontRespectsCustomSize() {
    let settings = EditorSettings()
    settings.fontSize = 20
    #expect(settings.font.pointSize == 20)
  }

  @Test
  func invalidFontNameFallsBackToSystemMonospaced() {
    let settings = EditorSettings()
    settings.fontName = "NonExistentFont-ThatDoesNotExist"
    settings.fontSize = 14
    let font = settings.font
    #expect(font.pointSize == 14)
  }

  // MARK: - colorPalette

  @Test
  func systemThemeReturnsNilPalette() {
    let settings = EditorSettings()
    settings.themeName = .system
    #expect(settings.colorPalette == nil)
  }

  @Test
  func draculaThemeReturnsPalette() {
    let settings = EditorSettings()
    settings.themeName = .dracula
    #expect(settings.colorPalette != nil)
  }

  // MARK: - monospaceFamilies

  @Test
  func monospaceFamiliesReturnsNonEmptyList() {
    let families = EditorSettings.monospaceFamilies
    #expect(!families.isEmpty)
  }

  @Test
  func monospaceFamiliesAreSorted() {
    let families = EditorSettings.monospaceFamilies
    #expect(families == families.sorted())
  }
}
