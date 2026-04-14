import Foundation

/// Callback-driven stream of backend steps.
///
/// The backend pushes a callout whenever new output is buffered for a
/// given job id; `notify(id:)` wakes the corresponding stream, which
/// then fetches the next step via the caller-supplied `fetch` closure.
/// Signals coalesce via `bufferingNewest(1)` so a flurry of per-byte
/// callouts collapses into a single step fetch.
@MainActor
final class BackendStepper<Step: Sendable> {
  private var signals: [UInt64: AsyncStream<Void>.Continuation] = [:]
  private let fetch: @Sendable (UInt64) async throws -> Step
  private let isTerminal: @Sendable (Step) -> Bool

  init(
    fetch: @escaping @Sendable (UInt64) async throws -> Step,
    isTerminal: @escaping @Sendable (Step) -> Bool
  ) {
    self.fetch = fetch
    self.isTerminal = isTerminal
  }

  /// Called from the backend callback when a step is ready for `id`.
  func notify(id: UInt64) {
    signals[id]?.yield()
  }

  /// Yields the first step immediately, then one per backend
  /// notification, terminating after yielding a step where
  /// `isTerminal` returns true.
  func steps(for id: UInt64) -> AsyncThrowingStream<Step, Error> {
    let (signalStream, signalContinuation) = AsyncStream<Void>.makeStream(
      bufferingPolicy: .bufferingNewest(1)
    )
    signals[id] = signalContinuation
    signalContinuation.yield() // trigger the first step

    let fetch = self.fetch
    let isTerminal = self.isTerminal
    return AsyncThrowingStream { continuation in
      let task = Task {
        defer { signalContinuation.finish() }
        do {
          for await _ in signalStream {
            let step = try await fetch(id)
            continuation.yield(step)
            if isTerminal(step) { break }
          }
          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
        await MainActor.run {
          _ = self.signals.removeValue(forKey: id)
        }
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }
}

@MainActor
enum BackendSteppers {
  static let execution = BackendStepper<ExecutionStep>(
    fetch: { try await Backend.shared.stepExecution($0) },
    isTerminal: \.isDone
  )

  static let install = BackendStepper<InstallStep>(
    fetch: { try await Backend.shared.stepInstall($0) },
    isTerminal: \.isTerminal
  )
}
