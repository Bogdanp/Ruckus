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
          if !doc.output.isEmpty {
            ScrollView {
              Text(doc.output)
                .font(.system(.body, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .frame(maxHeight: 200)
            .background(.bar)
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
      AsyncButton(
        action: { await evaluate() },
        options: Set<AsyncButton<Image>.Option>([.disabledWhileRunning, .showsProgressView]),
        label: { Image(systemName: "play.fill") }
      )
      .disabled(store.activeDocument == nil)
    }
  }

  private func evaluate() async {
    guard let doc = store.activeDocument else { return }
    do {
      let result = try await Backend.shared.evaluate(code: doc.code)
      let stdout = String(decoding: result.stdout, as: UTF8.self)
      let stderr = String(decoding: result.stderr, as: UTF8.self)
      doc.output = stdout + stderr
    } catch {
      doc.output = error.localizedDescription
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
