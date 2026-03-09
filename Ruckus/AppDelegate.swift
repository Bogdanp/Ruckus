import os
import UIKit
import WidgetKit

class AppDelegate: NSObject, UIApplicationDelegate {
  private static var executions: [UInt64: Weak<EditorDocument>] = [:]
  private static var outputBuffers: [UInt64: (stdout: OutputBuffer, stderr: OutputBuffer)] = [:]

  static func register(_ doc: EditorDocument, executionId: UInt64) {
    executions[executionId] = Weak(value: doc)
    outputBuffers[executionId] = (stdout: OutputBuffer(), stderr: OutputBuffer())
  }

  static func unregister(executionId: UInt64) {
    executions.removeValue(forKey: executionId)
    outputBuffers.removeValue(forKey: executionId)
  }

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    _ = Backend.shared.installCallback(onExecutorStep: { executionId in
      Task { @MainActor in
        AppDelegate.step(executionId)
      }
    })
    Task {
      do {
        try await Backend.shared.markOnExecutorStepInstalled()
      } catch {
        Logger.backend.error("\(#function): failed to mark executor step installed: \(error)")
      }
    }
    return true
  }

  private static func saveWidgetCache(executionId: UInt64, doc: EditorDocument) async {
    let stdout = outputBuffers[executionId]?.stdout.decoded ?? ""
    guard let scriptId = await EditorStore.shared.relativePath(for: doc) else {
      Logger.backend.debug("saveWidgetCache: skipped — no relative path for execution \(executionId)")
      return
    }
    ScriptOutputCache.save(output: stdout, for: scriptId)
    WidgetCenter.shared.reloadTimelines(ofKind: ScriptOutputCache.widgetKind)
  }

  private static func cleanupTempFile(_ doc: EditorDocument) {
    guard let tempPath = doc.tempPath else { return }
    doc.tempPath = nil
    Task {
      do {
        try await Backend.shared.deleteFile(atPath: tempPath)
      } catch {
        Logger.backend.warning("\(#function): temp file cleanup failed: \(error)")
      }
    }
  }

  private static func fetchCompletions(executionId: UInt64, doc: EditorDocument) {
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

  static func step(_ executionId: UInt64) {
    guard let doc = executions[executionId]?.value else { return }
    Task {
      do {
        let step = try await Backend.shared.stepExecution(executionId)
        let output: ExecutionOutput
        let isDone: Bool
        switch step {
        case .done(let value):
          output = value
          isDone = true
        case .more(let value):
          output = value
          isDone = false
        }
        let stdoutText = outputBuffers[executionId]?.stdout.decode(output.stdout) ?? ""
        if !stdoutText.isEmpty {
          doc.appendOutput(stdoutText, stream: .stdout)
        }
        let stderrText = outputBuffers[executionId]?.stderr.decode(output.stderr) ?? ""
        if !stderrText.isEmpty {
          doc.appendOutput(stderrText, stream: .stderr)
        }
        if isDone {
          let trailingStdout = outputBuffers[executionId]?.stdout.flush() ?? ""
          if !trailingStdout.isEmpty {
            doc.appendOutput(trailingStdout, stream: .stdout)
          }
          let trailingStderr = outputBuffers[executionId]?.stderr.flush() ?? ""
          if !trailingStderr.isEmpty {
            doc.appendOutput(trailingStderr, stream: .stderr)
          }
          doc.isEvaluating = false
          doc.executionId = nil
          await saveWidgetCache(executionId: executionId, doc: doc)
          fetchCompletions(executionId: executionId, doc: doc)
          executions.removeValue(forKey: executionId)
          outputBuffers.removeValue(forKey: executionId)
          cleanupTempFile(doc)
        }
      } catch {
        doc.appendOutput(error.localizedDescription + "\n", stream: .stderr)
        doc.isEvaluating = false
        doc.executionId = nil
        executions.removeValue(forKey: executionId)
        outputBuffers.removeValue(forKey: executionId)
        cleanupTempFile(doc)
      }
    }
  }
}
