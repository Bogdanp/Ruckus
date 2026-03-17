import Foundation
import Testing

@testable import Ruckus

@Suite
@MainActor
struct ExecutionRegistryTests {
  @Test
  func registerStoresDocumentAndBuffers() {
    let registry = ExecutionRegistry()
    let doc = EditorDocument()
    registry.register(doc, executionId: 1)

    #expect(registry.document(for: 1) === doc)
    var called = false
    registry.withBuffers(for: 1) { _, _ in called = true }
    #expect(called)
  }

  @Test
  func documentReturnsNilForUnknownId() {
    let registry = ExecutionRegistry()
    #expect(registry.document(for: 99) == nil)
  }

  @Test
  func withBuffersSkipsUnknownId() {
    let registry = ExecutionRegistry()
    var called = false
    registry.withBuffers(for: 99) { _, _ in called = true }
    #expect(!called)
  }

  @Test
  func unregisterRemovesBoth() {
    let registry = ExecutionRegistry()
    let doc = EditorDocument()
    registry.register(doc, executionId: 1)
    registry.unregister(executionId: 1, result: .completed)

    #expect(registry.document(for: 1) == nil)
    var called = false
    registry.withBuffers(for: 1) { _, _ in called = true }
    #expect(!called)
  }

  @Test
  func multipleExecutionsAreIndependent() {
    let registry = ExecutionRegistry()
    let doc1 = EditorDocument()
    let doc2 = EditorDocument()
    registry.register(doc1, executionId: 1)
    registry.register(doc2, executionId: 2)

    registry.unregister(executionId: 1, result: .completed)

    #expect(registry.document(for: 1) == nil)
    #expect(registry.document(for: 2) === doc2)
  }

  @Test
  func withBuffersMutatesInPlace() {
    let registry = ExecutionRegistry()
    let doc = EditorDocument()
    registry.register(doc, executionId: 1)

    registry.withBuffers(for: 1) { stdout, _ in
      let text = stdout.decode(Data("hello".utf8))
      #expect(text == "hello")
    }

    #expect(registry.decodedStdout(for: 1) == "hello")
  }

  @Test
  func decodedStdoutReturnsEmptyForUnknownId() {
    let registry = ExecutionRegistry()
    #expect(registry.decodedStdout(for: 99) == "")
  }

  @Test
  func awaitCompletionReturnsCompletedOnSuccess() async throws {
    let registry = ExecutionRegistry()
    let doc = EditorDocument()
    registry.register(doc, executionId: 1)

    Task { @MainActor in
      registry.unregister(executionId: 1, result: .completed)
    }

    let result = try await registry.awaitCompletion(of: 1)
    guard case .completed = result else {
      Issue.record("Expected .completed, got \(result)")
      return
    }
  }

  @Test
  func awaitCompletionReturnsStopped() async throws {
    let registry = ExecutionRegistry()
    let doc = EditorDocument()
    registry.register(doc, executionId: 1)

    Task { @MainActor in
      registry.unregister(executionId: 1, result: .stopped)
    }

    let result = try await registry.awaitCompletion(of: 1)
    guard case .stopped = result else {
      Issue.record("Expected .stopped, got \(result)")
      return
    }
  }

  @Test
  func awaitCompletionReturnsFailed() async throws {
    let registry = ExecutionRegistry()
    let doc = EditorDocument()
    registry.register(doc, executionId: 1)

    Task { @MainActor in
      registry.unregister(executionId: 1, result: .failed(TestError.bang))
    }

    let result = try await registry.awaitCompletion(of: 1)
    guard case .failed(let error) = result else {
      Issue.record("Expected .failed, got \(result)")
      return
    }
    #expect(error is TestError)
  }

  @Test
  func awaitCompletionReturnsImmediatelyWhenAlreadyUnregistered() async throws {
    let registry = ExecutionRegistry()
    let result = try await registry.awaitCompletion(of: 99)
    guard case .completed = result else {
      Issue.record("Expected .completed for already-unregistered id, got \(result)")
      return
    }
  }

  @Test
  func awaitCompletionThrowsOnCancellation() async {
    let registry = ExecutionRegistry()
    let doc = EditorDocument()
    registry.register(doc, executionId: 1)

    let task = Task {
      try await registry.awaitCompletion(of: 1)
    }
    task.cancel()

    do {
      _ = try await task.value
      Issue.record("Expected CancellationError")
    } catch {
      #expect(error is CancellationError)
    }
  }
}

private enum TestError: Error {
  case bang
}
