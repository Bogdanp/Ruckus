import NoiseBackend

extension Backend {
  private nonisolated(unsafe) static let executorStepReady: Future<String, Void> = {
    Backend.shared.installCallback(onExecutorStep: { executionId in
      Task { @MainActor in
        ExecutionStepper.shared.notify(executionId: executionId)
      }
    }).andThen { _ in
      Backend.shared.markOnExecutorStepInstalled()
    }
  }()

  static func ensureExecutorStepInstalled() async throws {
    try await FutureUtil.asyncify(executorStepReady)
  }
}
