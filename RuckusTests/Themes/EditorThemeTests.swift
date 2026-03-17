import Runestone
import Testing
import UIKit

@testable import Ruckus

@Suite
struct EditorThemeTests {

  // MARK: - init without palette

  @Test
  func initWithoutPaletteUsesDefaults() {
    let font = UIFont.monospacedSystemFont(ofSize: 16, weight: .regular)
    let theme = EditorTheme(font: font)

    #expect(theme.font == font)
    #expect(theme.lineNumberFont == font)
    #expect(theme.backgroundColor == .systemBackground)
  }

  // MARK: - init with palette

  @Test
  func initWithPaletteUsesThemeColors() {
    let font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
    let palette = ColorPalette.dracula
    let theme = EditorTheme(font: font, palette: palette)

    #expect(theme.textColor == palette.textColor)
    #expect(theme.gutterBackgroundColor == palette.gutterBackground)
    #expect(theme.gutterHairlineColor == palette.gutterHairline)
    #expect(theme.lineNumberColor == palette.lineNumber)
    #expect(theme.selectedLineBackgroundColor == palette.selectedLineBackground)
    #expect(theme.selectedLinesLineNumberColor == palette.selectedLinesLineNumber)
    #expect(theme.selectedLinesGutterBackgroundColor == palette.selectedLinesGutterBackground)
    #expect(theme.invisibleCharactersColor == palette.invisibleCharacters)
    #expect(theme.markedTextBackgroundColor == palette.markedTextBackground)
    #expect(theme.backgroundColor == palette.backgroundColor)
  }

  // MARK: - textColor(for:)

  @Test
  func textColorForHighlightWithPalette() {
    let font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
    let palette = ColorPalette.dracula
    let theme = EditorTheme(font: font, palette: palette)

    let keywordColor = theme.textColor(for: ColorPalette.Highlight.keyword)
    #expect(keywordColor == palette.syntaxColor(for: ColorPalette.Highlight.keyword))
  }

  @Test
  func textColorForUnknownHighlightReturnsNil() {
    let font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
    let palette = ColorPalette.dracula
    let theme = EditorTheme(font: font, palette: palette)

    let color = theme.textColor(for: "nonexistent")
    #expect(color == nil)
  }

  @Test
  func textColorFallsBackToDefaultThemeWithoutPalette() {
    let font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
    let theme = EditorTheme(font: font)

    let color = theme.textColor(for: ColorPalette.Highlight.keyword)
    #expect(color != nil)
  }

  // MARK: - fontTraits(for:)

  @Test
  func fontTraitsWithPalette() {
    let font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
    let palette = ColorPalette.dracula
    let theme = EditorTheme(font: font, palette: palette)

    let traits = theme.fontTraits(for: ColorPalette.Highlight.keyword)
    #expect(traits == palette.fontTraits(for: ColorPalette.Highlight.keyword))
  }

  @Test
  func fontTraitsFallsBackToDefaultThemeWithoutPalette() {
    let font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
    let theme = EditorTheme(font: font)

    let traits = theme.fontTraits(for: ColorPalette.Highlight.keyword)
    #expect(traits == .bold)
  }
}
