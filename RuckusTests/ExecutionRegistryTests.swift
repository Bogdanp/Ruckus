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
    registry.unregister(executionId: 1)

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

    registry.unregister(executionId: 1)

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
}
