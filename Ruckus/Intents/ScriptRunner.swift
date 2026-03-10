import Foundation

enum ScriptRunner {
  static func run(scriptAtPath path: String) async throws -> String {
    let id = try await Backend.shared.executeScript(atPath: path)
    let steps = await ExecutionStepper.shared.steps(for: id)
    var stdoutBuf = OutputBuffer()
    var stderrBuf = OutputBuffer()
    for try await step in steps {
      _ = stdoutBuf.decode(step.output.stdout)
      _ = stderrBuf.decode(step.output.stderr)
    }
    _ = stdoutBuf.flush()
    _ = stderrBuf.flush()
    let stdout = stdoutBuf.decoded
    if !stdout.isEmpty { return stdout }
    return stderrBuf.decoded
  }
}
