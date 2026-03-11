@MainActor
final class ExecutionRegistry {
  static let shared = ExecutionRegistry()

  private var executions: [UInt64: EditorDocument] = [:]
  private var outputBuffers: [UInt64: (stdout: OutputBuffer, stderr: OutputBuffer)] = [:]
  private var completions: [UInt64: [CheckedContinuation<Void, any Error>]] = [:]

  func register(_ doc: EditorDocument, executionId: UInt64) {
    executions[executionId] = doc
    outputBuffers[executionId] = (stdout: OutputBuffer(), stderr: OutputBuffer())
  }

  func unregister(executionId: UInt64) {
    executions.removeValue(forKey: executionId)
    outputBuffers.removeValue(forKey: executionId)
    if let waiting = completions.removeValue(forKey: executionId) {
      for continuation in waiting { continuation.resume(returning: ()) }
    }
  }

  func awaitCompletion(of executionId: UInt64) async throws {
    try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
        if executions[executionId] == nil {
          continuation.resume()
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
