import Foundation

@MainActor
final class InstallStepper {
  static let shared = InstallStepper()

  private var signals: [UInt64: AsyncStream<Void>.Continuation] = [:]

  /// Called from the ``Backend/installCallback(onInstallStep:)`` handler
  /// whenever the backend has a step ready for the given install.
  func notify(installId: UInt64) {
    signals[installId]?.yield()
  }

  /// Returns a callback-driven stream of install steps.
  ///
  /// The stream yields the first step immediately (without waiting for a
  /// callback), then one step per subsequent backend notification.  The
  /// stream finishes after yielding a `.done` or `.failed` step.
  func steps(for installId: UInt64) -> AsyncThrowingStream<InstallStep, Error> {
    let (signalStream, signalContinuation) = AsyncStream<Void>.makeStream()
    signals[installId] = signalContinuation
    signalContinuation.yield() // trigger the first step

    return AsyncThrowingStream { continuation in
      let task = Task {
        do {
          for await _ in signalStream {
            let step = try await Backend.shared.stepInstall(installId)
            continuation.yield(step)
            if step.isTerminal { break }
          }
          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
        await MainActor.run {
          _ = InstallStepper.shared.signals.removeValue(forKey: installId)
        }
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }
}
