import Foundation

enum ScriptRunner {
  static func run(scriptAtPath path: String) async throws -> String {
    let id = try await Backend.shared.executeScript(atPath: path)
    var stdout = ""
    while true {
      let step = try await Backend.shared.stepExecution(id)
      let output: ExecutionOutput
      let isDone: Bool
      switch step {
      case .done(let value):
        output = value
        isDone = true
      case .more(let value):
        output = value
        isDone = false
      }
      if let text = String(data: output.stdout, encoding: .utf8) {
        stdout += text
      }
      if isDone { break }
    }
    return stdout
  }
}
