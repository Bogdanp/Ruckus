import OSLog
import Testing

@testable import Ruckus

@Suite
struct LogsExportTests {

  @Test(arguments: [
    (OSLogEntryLog.Level.undefined, "undefined"),
    (OSLogEntryLog.Level.debug, "debug"),
    (OSLogEntryLog.Level.info, "info"),
    (OSLogEntryLog.Level.notice, "notice"),
    (OSLogEntryLog.Level.error, "error"),
    (OSLogEntryLog.Level.fault, "fault")
  ])
  func levelDescription(level: OSLogEntryLog.Level, expected: String) {
    #expect(level.description == expected)
  }

  @Test
  func unknownLevelDefaultsToDefault() {
    let unknown = OSLogEntryLog.Level(rawValue: 99)!
    #expect(unknown.description == "default")
  }
}
