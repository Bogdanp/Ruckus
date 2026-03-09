import Foundation
import UIKit

@Observable
class EditorDocument: Identifiable {
  enum Stream {
    case stdout
    case stderr
  }

  let id = UUID()
  var title: String
  var path: String?
  var code: String
  var output = NSAttributedString()
  var isDirty: Bool = false
  var isEvaluating: Bool = false
  var executionId: UInt64?
  var tempPath: String?
  var completions: [String] = []

  init(title: String = "Untitled", path: String? = nil, code: String = "") {
    self.title = title
    self.path = path
    self.code = code
  }

  func appendOutput(_ text: String, stream: Stream, font: UIFont? = nil) {
    let color: UIColor = switch stream {
    case .stdout: .label
    case .stderr: .systemRed
    }
    let outputFont = font ?? .monospacedSystemFont(ofSize: UIFont.smallSystemFontSize, weight: .regular)
    let attrs: [NSAttributedString.Key: Any] = [
      .foregroundColor: color,
      .font: outputFont
    ]
    let mutable = NSMutableAttributedString(attributedString: output)
    mutable.append(NSAttributedString(string: text, attributes: attrs))
    output = mutable
  }
}
