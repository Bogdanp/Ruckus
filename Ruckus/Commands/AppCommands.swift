import SwiftUI

struct AppCommands: Commands {
  @FocusedValue(\.saveAction) private var saveAction
  @FocusedValue(\.openFile) private var openFile
  @FocusedValue(\.viewOutput) private var viewOutput
  @FocusedValue(\.findAction) private var findAction
  @FocusedValue(\.findAndReplaceAction) private var findAndReplaceAction
  @FocusedValue(\.formatAction) private var formatAction
  @FocusedValue(\.shareAction) private var shareAction
  @FocusedValue(\.closeAction) private var closeAction

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
      .disabled(saveAction == nil || !store.hasActiveDocument)
      Button {
        saveAction?.saveAs()
      } label: {
        Label("Save As...", systemImage: "doc.badge.plus")
      }
      .keyboardShortcut("s", modifiers: [.command, .shift])
      .disabled(saveAction == nil || !store.hasActiveDocument)
      Button {
        Task { await store.revert() }
      } label: {
        Label("Revert", systemImage: "arrow.counterclockwise")
      }
      .disabled(!store.canRevert)
    }
    CommandGroup(after: .saveItem) {
      Button {
        shareAction?()
      } label: {
        Label("Share...", systemImage: "square.and.arrow.up")
      }
      .disabled(shareAction == nil)
      Divider()
      Button {
        closeAction?()
      } label: {
        Label("Close Tab", systemImage: "xmark")
      }
      .keyboardShortcut("w")
      .disabled(closeAction == nil)
    }
    CommandGroup(after: .pasteboard) {
      Button {
        findAction?()
      } label: {
        Label("Find...", systemImage: "magnifyingglass")
      }
      .keyboardShortcut("f")
      .disabled(findAction == nil)
      Button {
        findAndReplaceAction?()
      } label: {
        Label("Find and Replace...", systemImage: "arrow.left.arrow.right")
      }
      .keyboardShortcut("f", modifiers: [.command, .option])
      .disabled(findAndReplaceAction == nil)
      Divider()
      Button {
        Task { await formatAction?() }
      } label: {
        Label("Format", systemImage: "text.alignleft")
      }
      .keyboardShortcut("i", modifiers: [.command, .shift])
      .disabled(formatAction == nil)
    }
    CommandGroup(replacing: .toolbar) {
      Button {
        viewOutput?()
      } label: {
        Label("View Output...", systemImage: "terminal")
      }
      .keyboardShortcut("o", modifiers: [.command, .option])
      .disabled(!store.hasOutput)
    }
    CommandMenu("Run") {
      Button {
        Task { await store.execute() }
      } label: {
        Label("Run", systemImage: "play.fill")
      }
      .keyboardShortcut("r")
      .disabled(!store.canExecute)
      Button {
        Task { await store.stopExecution() }
      } label: {
        Label("Stop", systemImage: "stop.fill")
      }
      .keyboardShortcut(".", modifiers: .command)
      .disabled(!store.isExecuting)
    }
  }
}
