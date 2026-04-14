import Foundation
import os
import WidgetKit

@MainActor
final class ExecutionService {
  static let shared = ExecutionService()

  func runExecution(_ executionId: UInt64) {
    let registry = ExecutionRegistry.shared
    guard let doc = registry.document(for: executionId) else { return }
    Task {
      var result: ExecutionResult
      do {
        for try await step in BackendSteppers.execution.steps(for: executionId) {
          registry.withBuffers(for: executionId) { stdout, stderr in
            let stdoutText = stdout.decode(step.output.stdout)
            if !stdoutText.isEmpty {
              doc.appendOutput(stdoutText, stream: .stdout)
            }
            let stderrText = stderr.decode(step.output.stderr)
            if !stderrText.isEmpty {
              doc.appendOutput(stderrText, stream: .stderr)
            }
            if step.isDone {
              let trailingStdout = stdout.flush()
              if !trailingStdout.isEmpty {
                doc.appendOutput(trailingStdout, stream: .stdout)
              }
              let trailingStderr = stderr.flush()
              if !trailingStderr.isEmpty {
                doc.appendOutput(trailingStderr, stream: .stderr)
              }
            }
          }
        }
        result = .completed
        await saveWidgetCache(executionId: executionId, doc: doc)
        fetchCompletions(executionId: executionId, doc: doc)
      } catch {
        doc.appendOutput(error.localizedDescription + "\n", stream: .stderr)
        result = .failed(error)
      }
      finishExecution(executionId: executionId, doc: doc, result: result)
    }
  }

  func finishExecution(executionId: UInt64, doc: EditorDocument, result: ExecutionResult) {
    doc.isEvaluating = false
    doc.executionId = nil
    ExecutionRegistry.shared.unregister(executionId: executionId, result: result)
    EditorStore.shared.cleanupTempFile(doc)
  }

  private func saveWidgetCache(executionId: UInt64, doc: EditorDocument) async {
    let stdout = ExecutionRegistry.shared.decodedStdout(for: executionId)
    guard let scriptId = await EditorStore.shared.relativePath(for: doc) else {
      Logger.backend.debug("\(#function): skipped — no relative path for execution \(executionId)")
      return
    }
    ScriptOutputCache.save(output: stdout, for: scriptId)
    WidgetCenter.shared.reloadTimelines(ofKind: ScriptOutputCache.widgetKind)
  }

  private func fetchCompletions(executionId: UInt64, doc: EditorDocument) {
    Task {
      do {
        let symbols = try await Backend.shared.getExecutionSymbols(executionId)
        let sorted = symbols.sorted()
        if !sorted.isEmpty {
          doc.completions = sorted
        }
      } catch {
        Logger.backend.warning("\(#function): failed to fetch completions: \(error)")
      }
    }
  }
}
