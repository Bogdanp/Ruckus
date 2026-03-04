import Foundation

@Observable
class EditorDocument: Identifiable {
  let id = UUID()
  var title: String
  var path: String?
  var code: String
  var output: String = ""
  var isDirty: Bool = false
  var isEvaluating: Bool = false
  var executionId: UInt64?
  var tempPath: String?

  init(title: String = "Untitled", path: String? = nil, code: String = "") {
    self.title = title
    self.path = path
    self.code = code
  }
}
