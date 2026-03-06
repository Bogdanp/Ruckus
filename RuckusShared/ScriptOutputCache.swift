import Foundation

enum ScriptOutputCache {
  static let suiteName = "group.io.defn.Ruckus"

  private static let keyPrefix = "scriptOutput:"
  private static let timestampSuffix = ":timestamp"

  private static var defaults: UserDefaults? {
    UserDefaults(suiteName: suiteName)
  }

  static func save(output: String, for scriptPath: String) {
    let store = defaults
    store?.set(output, forKey: keyPrefix + scriptPath)
    store?.set(Date().timeIntervalSince1970, forKey: keyPrefix + scriptPath + timestampSuffix)
  }

  static func load(for scriptPath: String) -> (output: String, date: Date)? {
    guard let store = defaults,
          let output = store.string(forKey: keyPrefix + scriptPath) else {
      return nil
    }
    let timestamp = store.double(forKey: keyPrefix + scriptPath + timestampSuffix)
    guard timestamp > 0 else { return nil }
    return (output, Date(timeIntervalSince1970: timestamp))
  }
}
