import SwiftUI

@main
struct RuckusApp: App {
  @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(EditorStore.shared)
    }
  }
}
