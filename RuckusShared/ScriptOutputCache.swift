import Foundation

enum ScriptOutputCache {
  static let suiteName = "group.io.defn.Ruckus"
  static let widgetKind = "ScriptOutputWidget"

  private static let keyPrefix = "scriptOutput:"
  private static let timestampSuffix = ":timestamp"

  private static var defaults: UserDefaults? {
    UserDefaults(suiteName: suiteName)
  }

  static func save(output: String, for scriptId: String) {
    let store = defaults
    store?.set(output, forKey: keyPrefix + scriptId)
    store?.set(Date().timeIntervalSince1970, forKey: keyPrefix + scriptId + timestampSuffix)
  }

  static func remove(for scriptId: String) {
    let store = defaults
    store?.removeObject(forKey: keyPrefix + scriptId)
    store?.removeObject(forKey: keyPrefix + scriptId + timestampSuffix)
  }

  static func load(for scriptId: String) -> (output: String, date: Date)? {
    guard let store = defaults,
          let output = store.string(forKey: keyPrefix + scriptId) else {
      return nil
    }
    let timestamp = store.double(forKey: keyPrefix + scriptId + timestampSuffix)
    guard timestamp > 0 else { return nil }
    return (output, Date(timeIntervalSince1970: timestamp))
  }
}
