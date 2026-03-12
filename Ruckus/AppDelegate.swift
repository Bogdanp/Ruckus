import os
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    _ = Backend.shared.installCallback(onExecutorStep: { executionId in
      Task { @MainActor in
        ExecutionStepper.shared.notify(executionId: executionId)
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
}
