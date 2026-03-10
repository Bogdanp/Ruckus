import Foundation

@MainActor
final class ExecutionStepper {
  static let shared = ExecutionStepper()

  private var signals: [UInt64: AsyncStream<Void>.Continuation] = [:]

  /// Called from the ``Backend/installCallback(onExecutorStep:)`` handler
  /// whenever the backend has a step ready for the given execution.
  func notify(executionId: UInt64) {
    signals[executionId]?.yield()
  }

  /// Returns a callback-driven stream of execution steps.
  ///
  /// The stream yields the first step immediately (without waiting for a
  /// callback), then one step per subsequent backend notification.  The
  /// stream finishes after yielding a `.done` step.
  func steps(for executionId: UInt64) -> AsyncThrowingStream<ExecutionStep, Error> {
    let (signalStream, signalContinuation) = AsyncStream<Void>.makeStream()
    signals[executionId] = signalContinuation
    signalContinuation.yield() // trigger the first step

    return AsyncThrowingStream { continuation in
      let task = Task {
        do {
          for await _ in signalStream {
            let step = try await Backend.shared.stepExecution(executionId)
            continuation.yield(step)
            if step.isDone { break }
          }
          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
        await MainActor.run {
          _ = ExecutionStepper.shared.signals.removeValue(forKey: executionId)
        }
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }
}
