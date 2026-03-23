import Foundation
import Testing

@testable import Ruckus

@Suite
@MainActor
struct ExecutionServiceTests {

  private func runScript(_ code: String) async throws -> EditorDocument {
    try await Backend.ensureExecutorStepInstalled()
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

  @Test
  func runExecutionFiltersEmptyOutput() async throws {
    let doc = try await runScript("#lang racket/base\n(display \"\")(displayln \"hello\")\n")

    #expect(!doc.isEvaluating)
    #expect(doc.output.string.contains("hello"))

    // Verify that no empty-string runs snuck into the attributed string.
    var foundEmptyRun = false
    doc.output.enumerateAttributes(
      in: NSRange(location: 0, length: doc.output.length)
    ) { _, range, _ in
      let fragment = doc.output.attributedSubstring(from: range).string
      if fragment.isEmpty {
        foundEmptyRun = true
      }
    }
    #expect(!foundEmptyRun, "Output should not contain empty attributed-string runs")
  }

  // MARK: - bundled packages

  @Test
  func bundledPackageHttpEasyLoads() async throws {
    let doc = try await runScript(
      "#lang racket/base\n(require net/http-easy)\n(displayln \"http-easy loaded\")\n"
    )
    #expect(!doc.isEvaluating)
    #expect(doc.output.string.contains("http-easy loaded"))
  }

  // MARK: - package infrastructure

  @Test
  func pkgLibLoadsAndConfigIsWritable() async throws {
    let doc = try await runScript("""
      #lang racket/base
      (require pkg/lib setup/dirs)
      (define pkgs (find-pkgs-dir))
      (displayln (if (and pkgs (memq 'write (file-or-directory-permissions pkgs)))
                     "writable"
                     "not writable"))

      """
    )
    #expect(!doc.isEvaluating)
    #expect(doc.output.string.contains("writable"))
    #expect(!doc.output.string.contains("not writable"))
  }

  @Test
  func canInstallAndRequirePackage() async throws {
    // Install a package using pkg-install from pkg/lib.
    let installDoc = try await runScript("""
      #lang racket/base
      (require pkg/lib)
      (with-pkg-lock
        (pkg-install (list (pkg-desc "https://github.com/Bogdanp/marionette.git?path=marionette-lib" 'git #f #f #f))
                     #:dep-behavior 'search-auto))
      (displayln "install ok")

      """
    )
    #expect(!installDoc.isEvaluating)
    #expect(
      installDoc.output.string.contains("install ok"),
      "pkg-install failed: \(installDoc.output.string.prefix(500))"
    )

    defer {
      Task {
        _ = try? await runScript("""
          #lang racket/base
          (require pkg/lib)
          (with-pkg-lock
            (pkg-remove (list "marionette-lib")))

          """
        )
      }
    }

    // Require the installed package to prove it works.
    let requireDoc = try await runScript(
      "#lang racket/base\n(require marionette)\n(displayln \"marionette loaded\")\n"
    )
    #expect(!requireDoc.isEvaluating)
    #expect(requireDoc.output.string.contains("marionette loaded"))
  }
}
