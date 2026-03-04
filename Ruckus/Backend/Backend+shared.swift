import Foundation
import Noise

extension Backend {
  static let shared = Backend(
    withZo: Bundle.main.url(forResource: "res/core", withExtension: "zo")!,
    andMod: "main",
    andProc: "main",
    andBootArguments: .init(
      collectsDir: "../racket/collects",
      configDir: "../racket/etc"
    )
  )
}
