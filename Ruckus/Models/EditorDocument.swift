import Foundation
import UIKit

@Observable
@MainActor
class EditorDocument: Identifiable {
  enum Stream {
    case stdout
    case stderr
  }

  let id = UUID()
  var title: String
  var path: String?
  var code: String
  var output = NSMutableAttributedString()
  private(set) var outputVersion: UInt64 = 0
  @ObservationIgnored private var flushTask: Task<Void, Never>?
  var hasUnseenOutput = false
  var isDirty: Bool = false
  var isEvaluating: Bool = false
  var executionId: UInt64?
  var tempPath: String?
  var completions: [String] = []
  var savedContentOffset: CGPoint?
  var savedSelectedRange: NSRange?

  nonisolated static let codeReplaced = Notification.Name("EditorDocumentCodeReplaced")
  nonisolated static let codeReplacedKey = "code"

  /// Request an undoable whole-document replacement. The active editor
  /// observes this notification and applies the change through the text
  /// view's editing API so that undo, redo, and dirty-tracking work.
  func replaceCode(_ code: String) {
    NotificationCenter.default.post(
      name: Self.codeReplaced, object: self, userInfo: [Self.codeReplacedKey: code]
    )
  }

  init(title: String = "Untitled", path: String? = nil, code: String = "") {
    self.title = title
    self.path = path
    self.code = code
  }

  var canRevert: Bool { path != nil && isDirty }
  var hasOutput: Bool { output.length > 0 }

  func appendOutput(_ text: String, stream: Stream) {
    let color: UIColor = switch stream {
    case .stdout: .label
    case .stderr: .systemRed
    }
    let outputFont = UIFont.monospacedSystemFont(ofSize: UIFont.smallSystemFontSize, weight: .regular)
    let attrs: [NSAttributedString.Key: Any] = [
      .foregroundColor: color,
      .font: outputFont
    ]
    let wasEmpty = output.length == 0
    output.append(NSAttributedString(string: text, attributes: attrs))
    if wasEmpty {
      hasUnseenOutput = true
    }
    scheduleFlush()
  }

  func clearOutput() {
    cancelFlush()
    let range = NSRange(location: 0, length: output.length)
    output.deleteCharacters(in: range)
    notifyOutputChanged()
  }

  /// Bump the version counter to notify observers that `output` was mutated in place.
  private func notifyOutputChanged() {
    outputVersion &+= 1
  }

  private func scheduleFlush() {
    guard flushTask == nil else { return }
    flushTask = Task {
      try? await Task.sleep(for: .milliseconds(16))
      guard !Task.isCancelled else { return }
      self.flushTask = nil
      self.notifyOutputChanged()
    }
  }

  private func cancelFlush() {
    flushTask?.cancel()
    flushTask = nil
  }
}
