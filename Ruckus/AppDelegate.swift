import os
import UIKit
import WidgetKit

class AppDelegate: NSObject, UIApplicationDelegate {
  private static var executions: [UInt64: Weak<EditorDocument>] = [:]
  private static var stdoutBuffers: [UInt64: String] = [:]

  static func register(_ doc: EditorDocument, executionId: UInt64) {
    executions[executionId] = Weak(value: doc)
    stdoutBuffers[executionId] = ""
  }

  static func unregister(executionId: UInt64) {
    executions.removeValue(forKey: executionId)
    stdoutBuffers.removeValue(forKey: executionId)
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

  private static func saveWidgetCache(executionId: UInt64, doc: EditorDocument) {
    let stdout = stdoutBuffers.removeValue(forKey: executionId) ?? ""
    guard let fullPath = doc.path,
          let root = ScriptManifest.rootPath(),
          fullPath.hasPrefix(root) else { return }
    let scriptId = String(fullPath.dropFirst(root.count).drop { $0 == "/" })
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
        if let text = String(data: output.stdout, encoding: .utf8), !text.isEmpty {
          doc.appendOutput(text, stream: .stdout)
          stdoutBuffers[executionId, default: ""] += text
        }
        if let text = String(data: output.stderr, encoding: .utf8), !text.isEmpty {
          doc.appendOutput(text, stream: .stderr)
        }
        if isDone {
          doc.isEvaluating = false
          doc.executionId = nil
          saveWidgetCache(executionId: executionId, doc: doc)
          executions.removeValue(forKey: executionId)
          cleanupTempFile(doc)
        }
      } catch {
        doc.appendOutput(error.localizedDescription + "\n", stream: .stderr)
        doc.isEvaluating = false
        doc.executionId = nil
        stdoutBuffers.removeValue(forKey: executionId)
        executions.removeValue(forKey: executionId)
        cleanupTempFile(doc)
      }
    }
  }
}
