@MainActor
final class ExecutionRegistry {
  static let shared = ExecutionRegistry()

  private var executions: [UInt64: EditorDocument] = [:]
  private var outputBuffers: [UInt64: (stdout: OutputBuffer, stderr: OutputBuffer)] = [:]
  private var completions: [UInt64: [CheckedContinuation<ExecutionResult, any Error>]] = [:]

  func register(_ doc: EditorDocument, executionId: UInt64) {
    executions[executionId] = doc
    outputBuffers[executionId] = (stdout: OutputBuffer(), stderr: OutputBuffer())
  }

  func unregister(executionId: UInt64, result: ExecutionResult) {
    executions.removeValue(forKey: executionId)
    outputBuffers.removeValue(forKey: executionId)
    if let waiting = completions.removeValue(forKey: executionId) {
      for continuation in waiting { continuation.resume(returning: result) }
    }
  }

  func awaitCompletion(of executionId: UInt64) async throws -> ExecutionResult {
    try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ExecutionResult, any Error>) in
        if executions[executionId] == nil {
          continuation.resume(returning: .completed)
        } else {
          completions[executionId, default: []].append(continuation)
        }
      }
    } onCancel: {
      Task { @MainActor in
        if let waiting = completions.removeValue(forKey: executionId) {
          for continuation in waiting { continuation.resume(throwing: CancellationError()) }
        }
      }
    }
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
