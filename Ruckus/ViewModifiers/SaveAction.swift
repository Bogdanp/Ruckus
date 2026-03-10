import SwiftUI

struct SaveAction: ViewModifier {
  @Environment(EditorStore.self) private var store
  @State private var showSaveBrowser = false
  @State private var saveFilename = ""

  func body(content: Content) -> some View {
    content
      .sheet(isPresented: $showSaveBrowser) {
        SaveBrowserSheet(initialFilename: saveFilename) { directory, filename in
          guard let doc = store.activeDocument else { return }
          doc.title = filename
          doc.path = (directory as NSString).appendingPathComponent(filename)
          Task {
            do {
              try await store.save(doc)
            } catch {
              doc.appendOutput("Save failed: \(error.localizedDescription)", stream: .stderr)
            }
          }
        }
      }
      .environment(\.saveAction, SaveActionHandler(save: save, saveAs: saveAs))
  }

  private func save() {
    guard let doc = store.activeDocument else { return }
    if doc.path == nil {
      saveAs()
    } else {
      Task {
        do {
          try await store.save(doc)
        } catch {
          doc.appendOutput("Save failed: \(error.localizedDescription)", stream: .stderr)
        }
      }
    }
  }

  private func saveAs() {
    guard let doc = store.activeDocument else { return }
    saveFilename = doc.title == "Untitled" ? "" : doc.title
    showSaveBrowser = true
  }
}

struct SaveActionHandler: Sendable {
  var save: @MainActor @Sendable () -> Void = {}
  var saveAs: @MainActor @Sendable () -> Void = {}
}

private struct SaveActionKey: EnvironmentKey {
  static let defaultValue = SaveActionHandler()
}

extension EnvironmentValues {
  var saveAction: SaveActionHandler {
    get { self[SaveActionKey.self] }
    set { self[SaveActionKey.self] = newValue }
  }
}
