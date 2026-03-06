import Foundation

enum ScriptManifest {
  private static let scriptsKey = "scriptManifest:scripts"
  private static let rootPathKey = "scriptManifest:rootPath"

  private static var defaults: UserDefaults? {
    UserDefaults(suiteName: ScriptOutputCache.suiteName)
  }

  static func update(rootPath: String, scripts: [String]) {
    let store = defaults
    store?.set(rootPath, forKey: rootPathKey)
    store?.set(scripts, forKey: scriptsKey)
    store?.synchronize()
  }

  static func remove(script: String) {
    guard let store = defaults else { return }
    var current = scripts()
    current.removeAll { $0 == script }
    store.set(current, forKey: scriptsKey)
    store.synchronize()
  }

  static func scripts() -> [String] {
    defaults?.stringArray(forKey: scriptsKey) ?? []
  }

  static func rootPath() -> String? {
    defaults?.string(forKey: rootPathKey)
  }
}
