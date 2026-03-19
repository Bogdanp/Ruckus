import Foundation

enum ScriptManifest {
  private static let scriptsKey = "scriptManifest:scripts"
  private static let rootPathKey = "scriptManifest:rootPath"

  private static var defaults: UserDefaults? {
    UserDefaults(suiteName: ScriptOutputCache.suiteName)
  }

  static func update(rootPath: String, scripts: [String]) {
    guard let store = defaults else { return }
    store.set(rootPath, forKey: rootPathKey)
    store.set(scripts, forKey: scriptsKey)
  }

  static func remove(scriptAtPath path: String) {
    guard let store = defaults, let root = rootPath() else { return }
    let relative = path.relativePath(from: root)
    var current = scripts()
    current.removeAll { $0 == relative }
    store.set(current, forKey: scriptsKey)
  }

  static func removeAll(underDirectoryAtPath path: String) {
    guard let store = defaults, let root = rootPath() else { return }
    let prefix = path.relativePath(from: root) + "/"
    var current = scripts()
    current.removeAll { $0.hasPrefix(prefix) }
    store.set(current, forKey: scriptsKey)
  }

  static func scripts() -> [String] {
    defaults?.stringArray(forKey: scriptsKey) ?? []
  }

  static func rootPath() -> String? {
    defaults?.string(forKey: rootPathKey)
  }
}
