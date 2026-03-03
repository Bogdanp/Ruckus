import SwiftUI

struct ContentView: View {
  @State private var store = EditorStore()
  @State private var editorUndoManager: UndoManager?
  @State private var showFileBrowser = false
  @State private var showSaveAlert = false
  @State private var saveFilename = ""

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        TabBar(
          documents: store.documents,
          activeDocumentID: store.activeDocumentID,
          onSelect: { store.activeDocumentID = $0.id },
          onClose: { doc in
            if let id = doc.executionId {
              AppDelegate.unregister(executionId: id)
              Task { try? await Backend.shared.stopExecution(id) }
            }
            store.close(doc)
          },
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
          if !doc.output.isEmpty {
            Divider()
            ScrollView {
              Text(doc.output)
                .font(.system(.caption, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .padding(8)
            }
            .defaultScrollAnchor(.bottom)
            .frame(maxHeight: 200)
          }
        }
      }
      .navigationTitle(store.activeDocument?.title ?? "Ruckus")
      .navigationBarTitleDisplayMode(.inline)
      .toolbarTitleMenu {
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
        Button(action: revert) {
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
      .toolbar(content: leadingToolbar)
      .toolbar(content: trailingToolbar)
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
          Task { await saveDocument(doc) }
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text("Enter a name for this file.")
      }
    }
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
          Task { await stopExecution() }
        } label: {
          Image(systemName: "stop.fill")
        }
      } else {
        Button {
          Task { await execute() }
        } label: {
          Image(systemName: "play.fill")
        }
        .disabled(store.activeDocument == nil)
      }
    }
  }

  private func execute() async {
    guard let doc = store.activeDocument else { return }
    if doc.isDirty {
      await saveDocument(doc)
    }
    guard let path = doc.path else { return }
    doc.output = ""
    doc.isEvaluating = true
    do {
      let id = try await Backend.shared.executeScript(atPath: path)
      doc.executionId = id
      AppDelegate.register(doc, executionId: id)
      AppDelegate.step(id)
    } catch {
      doc.output = error.localizedDescription
      doc.isEvaluating = false
    }
  }

  private func stopExecution() async {
    guard let doc = store.activeDocument, let id = doc.executionId else { return }
    do {
      try await Backend.shared.stopExecution(id)
    } catch {
      doc.output += "\nStop failed: \(error.localizedDescription)"
    }
  }

  private func save() {
    guard let doc = store.activeDocument else { return }
    if doc.path == nil {
      saveAs()
    } else {
      Task { await saveDocument(doc) }
    }
  }

  private func saveAs() {
    guard let doc = store.activeDocument else { return }
    saveFilename = doc.title == "Untitled" ? "" : doc.title
    showSaveAlert = true
  }

  private func revert() {
    guard let doc = store.activeDocument, let path = doc.path else { return }
    Task {
      do {
        let content = try await Backend.shared.readFile(atPath: path)
        doc.code = content
        doc.isDirty = false
      } catch {
        doc.output = "Revert failed: \(error.localizedDescription)"
      }
    }
  }

  private func saveDocument(_ doc: EditorDocument) async {
    do {
      try await store.save(doc)
    } catch {
      doc.output = "Save failed: \(error.localizedDescription)"
    }
  }
}

#Preview {
  ContentView()
}
