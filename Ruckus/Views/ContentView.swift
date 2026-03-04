import SwiftUI

struct ContentView: View {
  @State private var store = EditorStore()
  @State private var editorUndoManager: UndoManager?
  @State private var showFileBrowser = false
  @State private var showSaveAlert = false
  @State private var saveFilename = ""

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
                textViewUndoManager: $editorUndoManager
              )
              .id(doc.id)
              .frame(maxWidth: .infinity, maxHeight: .infinity)
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
      .sheet(isPresented: $showFileBrowser) {
        FileBrowserSheet { path in
          Task {
            try? await store.open(path: path)
          }
        }
      }
      .alert("Save As", isPresented: $showSaveAlert) {
        TextField("Filename", text: $saveFilename)
        Button("Save") {
          guard let doc = store.activeDocument else { return }
          let name = saveFilename.hasSuffix(".rkt") ? saveFilename : saveFilename + ".rkt"
          doc.title = name
          Task {
            do {
              try await store.save(doc)
            } catch {
              doc.appendOutput("Save failed: \(error.localizedDescription)", stream: .stderr)
            }
          }
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text("Enter a name for this file.")
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
        showFileBrowser = true
      } label: {
        Image(systemName: "folder")
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
          Image(systemName: "stop.fill")
        }
      } else {
        Button {
          Task { await store.execute() }
        } label: {
          Image(systemName: "play.fill")
        }
        .disabled(store.activeDocument == nil)
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
    showSaveAlert = true
  }
}

#Preview {
  ContentView()
}
