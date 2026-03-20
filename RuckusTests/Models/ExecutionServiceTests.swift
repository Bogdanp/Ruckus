import Foundation
import Testing

@testable import Ruckus

@Suite
@MainActor
struct ExecutionServiceTests {

  private func runScript(_ code: String) async throws -> EditorDocument {
    let root = try await Backend.shared.getRootPath()
    let path = root.appendingPathComponent("test-\(UUID().uuidString).rkt")
    try await Backend.shared.save(code, to: path)
    defer { Task { try? await Backend.shared.deleteFile(atPath: path) } }

    let executionId = try await Backend.shared.executeScript(atPath: path)
    let doc = EditorDocument()
    doc.isEvaluating = true
    doc.executionId = executionId
    ExecutionRegistry.shared.register(doc, executionId: executionId)

    ExecutionService.shared.runExecution(executionId)
    _ = try await ExecutionRegistry.shared.awaitCompletion(of: executionId)
    return doc
  }

  // MARK: - finishExecution

  @Test
  func finishExecutionClearsEvaluatingState() {
    let doc = EditorDocument()
    doc.isEvaluating = true
    let executionId = UInt64.random(in: 1000...UInt64.max)
    doc.executionId = executionId
    ExecutionRegistry.shared.register(doc, executionId: executionId)

    ExecutionService.shared.finishExecution(
      executionId: executionId, doc: doc, result: .completed)

    #expect(!doc.isEvaluating)
    #expect(doc.executionId == nil)
  }

  @Test
  func finishExecutionUnregistersFromRegistry() {
    let doc = EditorDocument()
    let executionId = UInt64.random(in: 1000...UInt64.max)
    doc.executionId = executionId
    ExecutionRegistry.shared.register(doc, executionId: executionId)

    ExecutionService.shared.finishExecution(
      executionId: executionId, doc: doc, result: .completed)

    #expect(ExecutionRegistry.shared.document(for: executionId) == nil)
  }

  @Test
  func finishExecutionClearsTempPath() {
    let doc = EditorDocument()
    doc.tempPath = "/tmp/fake-temp-file.rkt"
    let executionId = UInt64.random(in: 1000...UInt64.max)
    doc.executionId = executionId
    ExecutionRegistry.shared.register(doc, executionId: executionId)

    ExecutionService.shared.finishExecution(
      executionId: executionId, doc: doc, result: .completed)

    #expect(doc.tempPath == nil)
  }

  @Test
  func finishExecutionHandlesAllResultVariants() {
    let results: [ExecutionResult] = [.completed, .stopped, .failed(CancellationError())]
    for result in results {
      let doc = EditorDocument()
      let executionId = UInt64.random(in: 1000...UInt64.max)
      doc.executionId = executionId
      ExecutionRegistry.shared.register(doc, executionId: executionId)

      ExecutionService.shared.finishExecution(
        executionId: executionId, doc: doc, result: result)

      #expect(!doc.isEvaluating)
      #expect(doc.executionId == nil)
    }
  }

  // MARK: - runExecution

  @Test
  func runExecutionProducesStdoutOutput() async throws {
    let doc = try await runScript("#lang racket/base\n(displayln \"hello\")\n")

    #expect(!doc.isEvaluating)
    #expect(doc.output.string.contains("hello"))
  }

  @Test
  func runExecutionCapturesStderr() async throws {
    let doc = try await runScript("#lang racket/base\n(eprintf \"err\")\n")

    #expect(doc.output.string.contains("err"))
  }

  @Test
  func runExecutionRecordsErrorOutput() async throws {
    let doc = try await runScript("#lang racket/base\n(error \"boom\")\n")

    #expect(!doc.isEvaluating)
    #expect(doc.output.string.contains("boom"))
  }
}
