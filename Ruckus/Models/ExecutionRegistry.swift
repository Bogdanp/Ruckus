@MainActor
final class ExecutionRegistry {
  static let shared = ExecutionRegistry()

  private var executions: [UInt64: EditorDocument] = [:]
  private var outputBuffers: [UInt64: (stdout: OutputBuffer, stderr: OutputBuffer)] = [:]

  func register(_ doc: EditorDocument, executionId: UInt64) {
    executions[executionId] = doc
    outputBuffers[executionId] = (stdout: OutputBuffer(), stderr: OutputBuffer())
  }

  func unregister(executionId: UInt64) {
    executions.removeValue(forKey: executionId)
    outputBuffers.removeValue(forKey: executionId)
  }

  func document(for executionId: UInt64) -> EditorDocument? {
    executions[executionId]
  }

  func decodedStdout(for executionId: UInt64) -> String {
    outputBuffers[executionId]?.stdout.decoded ?? ""
  }

  func withBuffers(
    for executionId: UInt64,
    _ body: (inout OutputBuffer, inout OutputBuffer) -> Void
  ) {
    guard var pair = outputBuffers[executionId] else { return }
    body(&pair.stdout, &pair.stderr)
    outputBuffers[executionId] = pair
  }
}
