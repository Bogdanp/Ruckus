import SwiftUI

struct AppCommands: Commands {
  @FocusedValue(\.saveAction) private var saveAction
  @FocusedValue(\.openFile) private var openFile
  @FocusedValue(\.viewOutput) private var viewOutput

  private var store: EditorStore { EditorStore.shared }

  var body: some Commands {
    CommandGroup(replacing: .newItem) {
      Button {
        store.newDocument()
      } label: {
        Label("New", systemImage: "doc")
      }
      .keyboardShortcut("n")
      Button {
        openFile?()
      } label: {
        Label("Open...", systemImage: "folder")
      }
      .keyboardShortcut("o", modifiers: [.command, .shift])
    }
    CommandGroup(replacing: .saveItem) {
      Button {
        saveAction?.save()
      } label: {
        Label("Save", systemImage: "doc.badge.arrow.up")
      }
      .keyboardShortcut("s")
      .disabled(saveAction == nil || store.activeDocument == nil)
      Button {
        saveAction?.saveAs()
      } label: {
        Label("Save As...", systemImage: "doc.badge.plus")
      }
      .keyboardShortcut("s", modifiers: [.command, .shift])
      .disabled(saveAction == nil || store.activeDocument == nil)
      Button {
        Task { await store.revert() }
      } label: {
        Label("Revert", systemImage: "arrow.counterclockwise")
      }
      .disabled(store.activeDocument?.canRevert != true)
    }
    CommandGroup(replacing: .toolbar) {
      Button {
        viewOutput?()
      } label: {
        Label("View Output...", systemImage: "terminal")
      }
      .keyboardShortcut("o", modifiers: [.command, .option])
      .disabled(store.activeDocument?.hasOutput != true)
    }
    CommandMenu("Run") {
      Button {
        Task { await store.execute() }
      } label: {
        Label("Run", systemImage: "play.fill")
      }
      .keyboardShortcut("r")
      .disabled(store.activeDocument == nil || store.activeDocument?.isEvaluating == true)
      Button {
        Task { await store.stopExecution() }
      } label: {
        Label("Stop", systemImage: "stop.fill")
      }
      .keyboardShortcut(".", modifiers: .command)
      .disabled(store.activeDocument?.isEvaluating != true)
    }
  }
}
