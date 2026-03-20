import os
import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
  override func buildMenu(with builder: any UIMenuBuilder) {
    super.buildMenu(with: builder)
    guard builder.system == .main else { return }
    builder.remove(menu: .open)
    builder.remove(menu: .openRecent)
  }

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    Task {
      do {
        try await Backend.ensureExecutorStepInstalled()
      } catch {
        Logger.backend.error("\(#function): failed to install executor step callback: \(error)")
      }
    }
    return true
  }
}
