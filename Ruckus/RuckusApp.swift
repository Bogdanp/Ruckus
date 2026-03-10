import SwiftUI

@main
struct RuckusApp: App {
  @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

  var body: some Scene {
    WindowGroup {
      ContentView()
        .modifier(SaveAction())
        .modifier(ShareAction())
        .environment(EditorStore.shared)
        .environment(EditorSettings.shared)
    }
  }
}
