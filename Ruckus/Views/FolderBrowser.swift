import SwiftUI

struct FolderBrowser<Header: View, FileRow: View>: View {
  var rootTitle: String
  var dismissLabel: String
  var allowsDeletion: Bool = false
  var onDelete: ((BrowserEntry) -> Void)?
  var hasOpenDocuments: ((BrowserEntry) -> Bool)?
  var onCloseDocuments: ((BrowserEntry) -> Void)?
  @Binding var currentDirectory: String
  @ViewBuilder var header: () -> Header
  @ViewBuilder var fileRow: (BrowserEntry) -> FileRow

  @Environment(\.dismiss) private var dismiss
  enum BrowserState {
    case loading
    case loaded([BrowserEntry])
    case error(String)
  }

  @State private var rootPath = ""
  @State private var state: BrowserState = .loading
  @State private var newFolderName = ""
  @State private var showNewFolderAlert = false
  @State private var folderToDelete: BrowserEntry?
  @State private var showDeleteFolderAlert = false
  @State private var fileToDelete: BrowserEntry?
  @State private var showOpenFileDeleteAlert = false

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        header()
        Group {
          switch state {
          case .loading:
            ProgressView()
              .frame(maxWidth: .infinity, maxHeight: .infinity)
          case .error(let message):
            ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(message))
          case .loaded(let entries):
            if entries.isEmpty {
              ContentUnavailableView("No Files", systemImage: "doc", description: Text("Save a file to see it here."))
            } else {
              list(entries)
            }
          }
        }
      }
      .navigationTitle(navigationTitle)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          if currentDirectory != rootPath {
            AsyncButton(
              options: AsyncButtonOption.allButCancel.subtracting([.showsSuccessIcon]),
              action: {
                currentDirectory = (currentDirectory as NSString).deletingLastPathComponent
                await loadEntries()
              },
              label: {
                Label("Back", systemImage: "chevron.left")
              }
            )
          } else {
            Button(dismissLabel) { dismiss() }
          }
        }
        ToolbarItem(placement: .primaryAction) {
          Button {
            newFolderName = ""
            showNewFolderAlert = true
          } label: {
            Image(systemName: "folder.badge.plus")
          }
        }
      }
      .alert(
        "Delete \"\(folderToDelete?.name ?? "")\"?",
        isPresented: $showDeleteFolderAlert,
        presenting: folderToDelete
      ) { folder in
        Button("Delete Folder", role: .destructive) {
          onCloseDocuments?(folder)
          Task { await deleteEntry(folder) }
        }
        Button("Cancel", role: .cancel) {}
      } message: { folder in
        if hasOpenDocuments?(folder) == true {
          Text("Open files in this folder will be closed. The folder and all its contents will be permanently deleted.")
        } else {
          Text("This will permanently delete the folder and all its contents.")
        }
      }
      .alert(
        "\"\(fileToDelete?.name ?? "")\" is open in the editor",
        isPresented: $showOpenFileDeleteAlert,
        presenting: fileToDelete
      ) { file in
        Button("Close and Delete", role: .destructive) {
          onCloseDocuments?(file)
          Task { await deleteEntry(file) }
        }
        Button("Cancel", role: .cancel) {}
      } message: { _ in
        Text("The file will be closed and permanently deleted.")
      }
      .alert("New Folder", isPresented: $showNewFolderAlert) {
        TextField("Folder name", text: $newFolderName)
        Button("Create") {
          Task { await createFolder() }
        }
        Button("Cancel", role: .cancel) {}
      }
    }
    .task {
      await loadRoot()
    }
  }

  private func list(_ entries: [BrowserEntry]) -> some View {
    List(entries) { entry in
      switch entry.kind {
      case .folder:
        AsyncButton(
          options: AsyncButtonOption.allButCancel.subtracting([.showsSuccessIcon]),
          action: {
            currentDirectory = entry.path
            await loadEntries()
          },
          label: {
            Label(entry.name, systemImage: "folder")
          }
        )
        .tint(.primary)
        .swipeActions(edge: .trailing) {
          if allowsDeletion {
            Button(role: .destructive) {
              folderToDelete = entry
              showDeleteFolderAlert = true
            } label: {
              Label("Delete", systemImage: "trash")
            }
          }
        }
      case .file:
        fileRow(entry)
          .swipeActions(edge: .trailing) {
            if allowsDeletion {
              Button(role: .destructive) {
                if hasOpenDocuments?(entry) == true {
                  fileToDelete = entry
                  showOpenFileDeleteAlert = true
                } else {
                  Task { await deleteEntry(entry) }
                }
              } label: {
                Label("Delete", systemImage: "trash")
              }
            }
          }
      }
    }
  }

  nonisolated static func navigationTitle(
    currentDirectory: String, rootPath: String, rootTitle: String
  ) -> String {
    if currentDirectory == rootPath {
      return rootTitle
    }
    return (currentDirectory as NSString).lastPathComponent
  }

  nonisolated static func sanitizeFolderName(_ name: String) -> String? {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }

  private var navigationTitle: String {
    Self.navigationTitle(
      currentDirectory: currentDirectory, rootPath: rootPath, rootTitle: rootTitle)
  }

  private func loadRoot() async {
    do {
      rootPath = try await Backend.shared.getRootPath()
      currentDirectory = rootPath
      await loadEntries()
    } catch {
      state = .error(error.localizedDescription)
    }
  }

  private func loadEntries() async {
    do {
      let rawEntries = try await Backend.shared.listFiles(atPath: currentDirectory)
      state = .loaded(rawEntries.toBrowserEntries())
    } catch {
      state = .error(error.localizedDescription)
    }
  }

  private func createFolder() async {
    guard let name = Self.sanitizeFolderName(newFolderName) else { return }
    let path = currentDirectory.appendingPathComponent(name)
    do {
      try await Backend.shared.createDirectory(atPath: path)
      await loadEntries()
    } catch {
      state = .error(error.localizedDescription)
    }
  }

  private func deleteEntry(_ entry: BrowserEntry) async {
    do {
      switch entry.kind {
      case .file:
        try await Backend.shared.deleteFile(atPath: entry.path)
      case .folder:
        try await Backend.shared.deleteDirectory(atPath: entry.path)
      }
      if case .loaded(var entries) = state {
        entries.removeAll { $0.id == entry.id }
        state = .loaded(entries)
      }
      onDelete?(entry)
    } catch {
      state = .error(error.localizedDescription)
    }
  }
}
