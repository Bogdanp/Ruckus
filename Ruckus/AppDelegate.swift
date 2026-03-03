import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
  private static var executions: [UInt64: EditorDocument] = [:]

  static func register(_ doc: EditorDocument, executionId: UInt64) {
    executions[executionId] = doc
  }

  static func unregister(executionId: UInt64) {
    executions.removeValue(forKey: executionId)
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
      try? await Backend.shared.markOnExecutorStepInstalled()
    }
    return true
  }

  static func step(_ executionId: UInt64) {
    guard let doc = executions[executionId] else { return }
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
          doc.output += text
        }
        if let text = String(data: output.stderr, encoding: .utf8), !text.isEmpty {
          doc.output += text
        }
        if isDone {
          doc.isEvaluating = false
          doc.executionId = nil
          executions.removeValue(forKey: executionId)
        }
      } catch {
        doc.output += error.localizedDescription + "\n"
        doc.isEvaluating = false
        doc.executionId = nil
        executions.removeValue(forKey: executionId)
      }
    }
  }
}
