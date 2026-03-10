import SwiftUI

struct ShareAction: ViewModifier {
  @Environment(EditorStore.self) private var store
  @State private var shareFileURL: IdentifiableURL?
  @State private var shareError: String?

  func body(content: Content) -> some View {
    content
      .sheet(item: $shareFileURL) { item in
        ActivitySheet(items: [item.url])
      }
      .onChange(of: shareFileURL?.url) { oldURL, _ in
        if let oldURL {
          try? FileManager.default.removeItem(at: oldURL.deletingLastPathComponent())
        }
      }
      .alert("Share Failed", isPresented: Binding(
        get: { shareError != nil },
        set: { if !$0 { shareError = nil } }
      )) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(shareError ?? "")
      }
      .environment(\.shareAction, ShareActionHandler(share: share))
  }

  private func share() {
    guard let document = store.activeDocument else { return }
    let filename = document.title.hasSuffix(".rkt") ? document.title : document.title + ".rkt"
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    do {
      try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
      let fileURL = tempDir.appendingPathComponent(filename)
      try document.code.write(to: fileURL, atomically: true, encoding: .utf8)
      shareFileURL = IdentifiableURL(url: fileURL)
    } catch {
      shareError = error.localizedDescription
    }
  }
}

struct ShareActionHandler: Sendable {
  var share: @MainActor @Sendable () -> Void
}

private struct ShareActionKey: EnvironmentKey {
  static let defaultValue = ShareActionHandler(share: {})
}

extension EnvironmentValues {
  var shareAction: ShareActionHandler {
    get { self[ShareActionKey.self] }
    set { self[ShareActionKey.self] = newValue }
  }
}
