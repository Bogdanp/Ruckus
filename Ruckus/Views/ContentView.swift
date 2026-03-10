import os
import SwiftUI
import WidgetKit

struct ContentView: View {
  @Environment(EditorStore.self) private var store
  @Environment(\.saveAction) private var saveAction
  @Environment(\.shareAction) private var shareAction
  @State private var editorUndoManager: UndoManager?
  @State private var activeSheet: ActiveSheet?

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
                document: doc,
                textViewUndoManager: $editorUndoManager,
                completions: doc.completions.isEmpty ? store.baseCompletions : doc.completions
              )
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .layoutPriority(-1)
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
      .sheet(item: $activeSheet) { sheet in
        switch sheet {
        case .output:
          if let doc = store.activeDocument {
            OutputSheetView(text: doc.output)
          }
        case .settings:
          SettingsView()
        case .fileBrowser:
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
      }
      .onChange(of: store.activeDocument?.hasUnseenOutput) { _, new in
        guard new == true else { return }
        store.activeDocument?.hasUnseenOutput = false
        activeSheet = .output
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
      activeSheet = .fileBrowser
    } label: {
      Label("Open...", systemImage: "folder")
    }
    Divider()
    Button(action: saveAction.save) {
      Label("Save", systemImage: "doc.badge.arrow.up")
    }
    .disabled(store.activeDocument == nil)
    Button(action: saveAction.saveAs) {
      Label("Save As...", systemImage: "doc.badge.plus")
    }
    .disabled(store.activeDocument == nil)
    Button(action: shareAction.share) {
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
        activeSheet = .settings
      } label: {
        Image(systemName: "gearshape")
      }
    }
  }

  @ToolbarContentBuilder
  private func trailingToolbar() -> some ToolbarContent {
    ToolbarItem(placement: .primaryAction) {
      Button {
        activeSheet = .output
      } label: {
        Label("Output", systemImage: "terminal")
          .labelStyle(.iconOnly)
      }
      .disabled(store.activeDocument?.output.length ?? 0 == 0)
    }
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
}

#Preview {
  ContentView()
    .environment(EditorStore.shared)
    .environment(EditorSettings.shared)
}
