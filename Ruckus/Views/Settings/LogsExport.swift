import OSLog
import SwiftUI

struct LogsExport: Transferable {
  static var transferRepresentation: some TransferRepresentation {
    DataRepresentation(exportedContentType: .text) { _ in
      var data = Data()
      let entries = try await getRecentEntries()
      entries.forEach { entry in
        guard let entry = entry as? OSLogEntryLog else { return }
        let level = entry.level.description
        let line = "\(entry.date) [\(entry.subsystem).\(entry.category)] [\(level)] \(entry.composedMessage)\n"
        data.append(contentsOf: line.utf8)
      }
      return data
    }.suggestedFileName("logs.txt")
  }

  nonisolated static func getRecentEntries() async throws -> AnySequence<OSLogEntry> {
    let store = try OSLogStore(scope: .currentProcessIdentifier)
    return try store.getEntries(
      at: store.position(timeIntervalSinceEnd: 86400),
      matching: NSPredicate(format: "subsystem == %@", "com.ruckus.app"))
  }
}

extension OSLogEntryLog.Level {
  var description: String {
    switch self {
    case .undefined: "undefined"
    case .debug: "debug"
    case .info: "info"
    case .notice: "notice"
    case .error: "error"
    case .fault: "fault"
    default: "default"
    }
  }
}
