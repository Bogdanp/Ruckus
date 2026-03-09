import os
import SwiftUI
import WidgetKit

struct ContentView: View {
  @State private var store = EditorStore()
  @State private var editorSettings = EditorSettings()
  @State private var editorUndoManager: UndoManager?
  @State private var showFileBrowser = false
  @State private var showSaveBrowser = false
  @State private var saveFilename = ""
  @State private var shareFileURL: URL?
  @State private var shareError: String?
  @State private var showSettings = false

  var body: some View {
    NavigationStack {
      Group {
        if store.isLoading {
          ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          VStack(spacing: 0) {
            TabBar(
              documents: store.documents,
              activeDocumentID: store.activeDocumentID,
              onSelect: { store.selectDocument($0) },
              onClose: { store.close($0) },
              onNew: { store.newDocument() }
            )
            if let doc = store.activeDocument {
              CodeEditingView(
                text: Binding(
                  get: { doc.code },
                  set: {
                    doc.code = $0
                    doc.isDirty = true
                  }
                ),
                textViewUndoManager: $editorUndoManager,
                completions: doc.completions,
                settings: editorSettings
              )
              .id(doc.id)
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .layoutPriority(-1)
              if doc.output.length > 0 {
                OutputPanelView(text: doc.output)
              }
            }
          }
        }
      }
      .navigationTitle(store.activeDocument?.title ?? "Ruckus")
      .navigationBarTitleDisplayMode(.inline)
      .toolbarTitleMenu(content: titleMenu)
      .toolbar(content: leadingToolbar)
      .toolbar(content: trailingToolbar)
      .task {
        await store.restoreSession()
      }
      .sheet(isPresented: $showSettings) {
        SettingsView(settings: editorSettings)
      }
      .sheet(isPresented: $showFileBrowser) {
        FileBrowserSheet { path in
          Task {
            do {
              try await store.open(path: path)
            } catch {
              Logger.editor.error("\(#function): failed to open file at \(path): \(error)")
            }
          }
        }
      }
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
      .sheet(item: $shareFileURL) { url in
        ActivitySheet(items: [url])
      }
      .onChange(of: shareFileURL) { oldURL, _ in
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
      .onOpenURL { url in
        if url.scheme == "ruckus", url.host == "refresh" {
          guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                let scriptId = components.queryItems?.first(where: { $0.name == "script" })?.value,
                let root = ScriptManifest.rootPath() else { return }
          let fullPath = (root as NSString).appendingPathComponent(scriptId)
          Task {
            do {
              try await store.open(path: fullPath)
            } catch {
              Logger.editor.error("\(#function): failed to open file from URL: \(error)")
            }
            await store.execute()
          }
        } else {
          Task {
            await store.importFile(from: url)
          }
        }
      }
    }
  }

  @ViewBuilder
  private func titleMenu() -> some View {
    Button {
      store.newDocument()
    } label: {
      Label("New", systemImage: "doc")
    }
    Button {
      showFileBrowser = true
    } label: {
      Label("Open...", systemImage: "folder")
    }
    Divider()
    Button(action: save) {
      Label("Save", systemImage: "doc.badge.arrow.up")
    }
    .disabled(store.activeDocument == nil)
    Button(action: saveAs) {
      Label("Save As...", systemImage: "doc.badge.plus")
    }
    .disabled(store.activeDocument == nil)
    Button(action: share) {
      Label("Share...", systemImage: "square.and.arrow.up")
    }
    .disabled(store.activeDocument == nil)
    Button {
      Task { await store.revert() }
    } label: {
      Label("Revert", systemImage: "arrow.counterclockwise")
    }
    .disabled(store.activeDocument?.path == nil || store.activeDocument?.isDirty != true)
    Divider()
    Button {
      editorUndoManager?.undo()
    } label: {
      Label("Undo", systemImage: "arrow.uturn.backward")
    }
    .disabled(editorUndoManager?.canUndo != true)
    Button {
      editorUndoManager?.redo()
    } label: {
      Label("Redo", systemImage: "arrow.uturn.forward")
    }
    .disabled(editorUndoManager?.canRedo != true)
  }

  @ToolbarContentBuilder
  private func leadingToolbar() -> some ToolbarContent {
    ToolbarItem(placement: .topBarLeading) {
      Button {
        showSettings = true
      } label: {
        Image(systemName: "gearshape")
      }
    }
  }

  @ToolbarContentBuilder
  private func trailingToolbar() -> some ToolbarContent {
    ToolbarItem(placement: .primaryAction) {
      if store.activeDocument?.isEvaluating == true {
        Button {
          Task { await store.stopExecution() }
        } label: {
          Label("Stop", systemImage: "stop.fill")
            .labelStyle(.iconOnly)
        }
      } else {
        Button {
          Task { await store.execute() }
        } label: {
          Label("Run", systemImage: "play.fill")
            .labelStyle(.iconOnly)
        }
        .disabled(store.activeDocument == nil || store.activeDocument?.isEvaluating == true)
      }
    }
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

  private func share() {
    guard let doc = store.activeDocument else { return }
    let filename = doc.title.hasSuffix(".rkt") ? doc.title : doc.title + ".rkt"
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    do {
      try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
      let fileURL = tempDir.appendingPathComponent(filename)
      try doc.code.write(to: fileURL, atomically: true, encoding: .utf8)
      shareFileURL = fileURL
    } catch {
      shareError = error.localizedDescription
    }
  }
}

#Preview {
  ContentView()
}
