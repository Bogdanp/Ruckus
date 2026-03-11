enum ColorThemeName: String, CaseIterable, Identifiable {
  case system = "System"
  case catppuccinMocha = "Catppuccin Mocha"
  case dracula = "Dracula"
  case gitHubLight = "GitHub Light"
  case gruvboxDark = "Gruvbox Dark"
  case monokai = "Monokai"
  case nord = "Nord"
  case oneDark = "One Dark"
  case solarizedLight = "Solarized Light"

  var id: String { rawValue }

  var palette: ColorPalette? {
    switch self {
    case .system: return nil
    case .catppuccinMocha: return .catppuccinMocha
    case .dracula: return .dracula
    case .gitHubLight: return .gitHubLight
    case .gruvboxDark: return .gruvboxDark
    case .monokai: return .monokai
    case .nord: return .nord
    case .oneDark: return .oneDark
    case .solarizedLight: return .solarizedLight
    }
  }
}
