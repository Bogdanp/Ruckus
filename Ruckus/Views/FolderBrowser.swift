import SwiftUI

struct FolderBrowser<Header: View, FileRow: View>: View {
  var rootTitle: String
  var dismissLabel: String
  var allowsDeletion: Bool = false
  @Binding var currentDirectory: String
  @ViewBuilder var header: () -> Header
  @ViewBuilder var fileRow: (BrowserEntry) -> FileRow

  @Environment(\.dismiss) private var dismiss
  @State private var rootPath = ""
  @State private var entries: [BrowserEntry] = []
  @State private var isLoading = true
  @State private var error: String?
  @State private var newFolderName = ""
  @State private var showNewFolderAlert = false

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        header()
        Group {
          if isLoading {
            ProgressView()
              .frame(maxWidth: .infinity, maxHeight: .infinity)
          } else if let error {
            ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
          } else if entries.isEmpty {
            ContentUnavailableView("No Files", systemImage: "doc", description: Text("Save a file to see it here."))
          } else {
            list
          }
        }
      }
      .navigationTitle(navigationTitle)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          if currentDirectory != rootPath {
            Button {
              currentDirectory = (currentDirectory as NSString).deletingLastPathComponent
              Task { await loadEntries() }
            } label: {
              Label("Back", systemImage: "chevron.left")
            }
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

  private var list: some View {
    List(entries) { entry in
      switch entry.kind {
      case .folder:
        Button {
          currentDirectory = entry.path
          Task { await loadEntries() }
        } label: {
          Label(entry.name, systemImage: "folder")
        }
        .tint(.primary)
      case .file:
        fileRow(entry)
          .swipeActions(edge: .trailing) {
            if allowsDeletion {
              Button(role: .destructive) {
                Task { await deleteEntry(entry) }
              } label: {
                Label("Delete", systemImage: "trash")
              }
            }
          }
      }
    }
  }

  private var navigationTitle: String {
    if currentDirectory == rootPath {
      return rootTitle
    }
    return (currentDirectory as NSString).lastPathComponent
  }

  private func loadRoot() async {
    do {
      rootPath = try await Backend.shared.getRootPath()
      currentDirectory = rootPath
      await loadEntries()
    } catch {
      self.error = error.localizedDescription
      isLoading = false
    }
  }

  private func loadEntries() async {
    do {
      let rawEntries = try await Backend.shared.listFiles(atPath: currentDirectory)
      entries = rawEntries.toBrowserEntries()
      isLoading = false
    } catch {
      self.error = error.localizedDescription
      isLoading = false
    }
  }

  private func createFolder() async {
    let name = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !name.isEmpty else { return }
    let path = (currentDirectory as NSString).appendingPathComponent(name)
    do {
      try await Backend.shared.createDirectory(atPath: path)
      await loadEntries()
    } catch {
      self.error = error.localizedDescription
    }
  }

  private func deleteEntry(_ entry: BrowserEntry) async {
    do {
      try await Backend.shared.deleteFile(atPath: entry.path)
      entries.removeAll { $0.id == entry.id }
    } catch {
      self.error = error.localizedDescription
    }
  }
}
