import os

extension Logger {
  static let backend = Logger(subsystem: "com.ruckus.app", category: "backend")
  static let editor = Logger(subsystem: "com.ruckus.app", category: "editor")
  static let session = Logger(subsystem: "com.ruckus.app", category: "session")
}
