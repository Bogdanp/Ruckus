import Testing

@testable import Ruckus

@Suite
struct ColorThemeNameTests {

  @Test
  func systemThemeReturnsNilPalette() {
    #expect(ColorThemeName.system.palette == nil)
  }

  @Test(arguments: ColorThemeName.allCases.filter { $0 != .system })
  func nonSystemThemesReturnPalette(theme: ColorThemeName) {
    #expect(theme.palette != nil)
  }

  @Test
  func idMatchesRawValue() {
    for theme in ColorThemeName.allCases {
      #expect(theme.id == theme.rawValue)
    }
  }

  @Test
  func rawValueRoundTrips() {
    for theme in ColorThemeName.allCases {
      #expect(ColorThemeName(rawValue: theme.rawValue) == theme)
    }
  }

  @Test
  func invalidRawValueReturnsNil() {
    #expect(ColorThemeName(rawValue: "NonExistentTheme") == nil)
  }
}
