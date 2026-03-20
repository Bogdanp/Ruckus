import Foundation
import Testing

@testable import Ruckus

@Suite
@MainActor
struct ExecutionStepperTests {

  private func executeScript(_ code: String) async throws -> (path: String, executionId: UInt64) {
    try await Backend.ensureExecutorStepInstalled()
    let root = try await Backend.shared.getRootPath()
    let path = root.appendingPathComponent("test-\(UUID().uuidString).rkt")
    try await Backend.shared.save(code, to: path)
    let executionId = try await Backend.shared.executeScript(atPath: path)
    return (path, executionId)
  }

  @Test
  func stepsYieldsOutputAndTerminates() async throws {
    let (path, executionId) = try await executeScript(
      "#lang racket/base\n(displayln \"hi\")\n")
    defer { Task { try? await Backend.shared.deleteFile(atPath: path) } }

    var steps: [ExecutionStep] = []
    for try await step in ExecutionStepper.shared.steps(for: executionId) {
      steps.append(step)
    }

    #expect(!steps.isEmpty)
    #expect(steps.last?.isDone == true)

    let hasStdout = steps.contains { step in
      switch step {
      case .more(let output), .done(let output):
        return !output.stdout.isEmpty
      }
    }
    #expect(hasStdout)
  }

  @Test
  func notifyForUnknownIdIsNoOp() {
    ExecutionStepper.shared.notify(executionId: UInt64.random(in: 1000...UInt64.max))
  }

  @Test
  func streamCancellationTerminates() async throws {
    let (path, executionId) = try await executeScript(
      "#lang racket/base\n(sleep 10)\n")
    defer { Task { try? await Backend.shared.deleteFile(atPath: path) } }
    defer { Task { try? await Backend.shared.stopExecution(executionId) } }

    let task = Task {
      for try await _ in ExecutionStepper.shared.steps(for: executionId) {}
    }

    try await Task.sleep(for: .milliseconds(100))
    task.cancel()

    // Stream should terminate (either by cancellation error or normal finish)
    _ = await task.result
  }

  @Test
  func multipleConcurrentExecutions() async throws {
    let (pathA, idA) = try await executeScript(
      "#lang racket/base\n(displayln \"aaa\")\n")
    defer { Task { try? await Backend.shared.deleteFile(atPath: pathA) } }

    let (pathB, idB) = try await executeScript(
      "#lang racket/base\n(displayln \"bbb\")\n")
    defer { Task { try? await Backend.shared.deleteFile(atPath: pathB) } }

    let stepsA = ExecutionStepper.shared.steps(for: idA)
    let stepsB = ExecutionStepper.shared.steps(for: idB)

    var stdoutA = Data()
    var stdoutB = Data()

    // Consume both streams concurrently
    let taskA = Task { @MainActor in
      for try await step in stepsA {
        switch step {
        case .more(let output), .done(let output):
          stdoutA.append(output.stdout)
        }
      }
    }

    let taskB = Task { @MainActor in
      for try await step in stepsB {
        switch step {
        case .more(let output), .done(let output):
          stdoutB.append(output.stdout)
        }
      }
    }

    try await taskA.value
    try await taskB.value

    let outputA = String(data: stdoutA, encoding: .utf8) ?? ""
    let outputB = String(data: stdoutB, encoding: .utf8) ?? ""

    #expect(outputA.contains("aaa"))
    #expect(!outputA.contains("bbb"))
    #expect(outputB.contains("bbb"))
    #expect(!outputB.contains("aaa"))
  }
}
