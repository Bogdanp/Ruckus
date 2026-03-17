import Runestone
import Testing
import UIKit

@testable import Ruckus

@Suite
struct ColorPaletteTests {

  // MARK: - syntaxColor

  @Test
  func syntaxColorReturnsColorForKnownName() {
    let palette = ColorPalette.dracula
    let color = palette.syntaxColor(for: ColorPalette.Highlight.keyword)
    #expect(color != nil)
  }

  @Test
  func syntaxColorReturnsNilForUnknownName() {
    let palette = ColorPalette.dracula
    let color = palette.syntaxColor(for: "nonexistent.highlight.name")
    #expect(color == nil)
  }

  // MARK: - fontTraits

  @Test
  func fontTraitsReturnsBoldForBoldName() {
    let palette = ColorPalette.dracula
    let traits = palette.fontTraits(for: ColorPalette.Highlight.keyword)
    #expect(traits == .bold)
  }

  @Test
  func fontTraitsReturnsEmptyForNonBoldName() {
    let palette = ColorPalette.dracula
    let traits = palette.fontTraits(for: ColorPalette.Highlight.comment)
    #expect(traits == [])
  }

  @Test
  func fontTraitsReturnsEmptyForUnknownName() {
    let palette = ColorPalette.dracula
    let traits = palette.fontTraits(for: "unknown")
    #expect(traits == [])
  }

  // MARK: - all themes have required colors

  @Test(arguments: ColorThemeName.allCases.filter { $0 != .system })
  func themeHasRainbowColors(theme: ColorThemeName) {
    let palette = theme.palette!
    #expect(!palette.rainbowColors.isEmpty)
  }

  @Test(arguments: ColorThemeName.allCases.filter { $0 != .system })
  func themeHasSyntaxColors(theme: ColorThemeName) {
    let palette = theme.palette!
    #expect(!palette.syntaxColors.isEmpty)
    // Every theme should have at least keyword and comment colors
    #expect(palette.syntaxColor(for: ColorPalette.Highlight.keyword) != nil)
    #expect(palette.syntaxColor(for: ColorPalette.Highlight.comment) != nil)
    #expect(palette.syntaxColor(for: ColorPalette.Highlight.string) != nil)
  }
}
