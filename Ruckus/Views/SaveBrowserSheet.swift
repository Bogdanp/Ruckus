import SwiftUI

struct SaveBrowserSheet: View {
  var initialFilename: String
  var onSave: (String, String) -> Void
  @Environment(\.dismiss) private var dismiss
  @State private var rootPath = ""
  @State private var currentPath = ""
  @State private var entries: [BrowserEntry] = []
  @State private var isLoading = true
  @State private var error: String?
  @State private var filename = ""
  @State private var newFolderName = ""
  @State private var showNewFolderAlert = false

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        HStack {
          TextField("Filename", text: $filename)
            .textFieldStyle(.roundedBorder)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
          Button("Save") {
            let name = filename.hasSuffix(".rkt") ? filename : filename + ".rkt"
            onSave(currentPath, name)
            dismiss()
          }
          .buttonStyle(.borderedProminent)
          .disabled(filename.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        Divider()
        Group {
          if isLoading {
            ProgressView()
              .frame(maxWidth: .infinity, maxHeight: .infinity)
          } else if let error {
            ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
          } else if entries.isEmpty {
            ContentUnavailableView("Empty Folder", systemImage: "folder", description: Text("No files here yet."))
              .frame(maxWidth: .infinity, maxHeight: .infinity)
          } else {
            List(entries) { entry in
              switch entry.kind {
              case .folder:
                Button {
                  currentPath = entry.path
                  Task { await loadEntries() }
                } label: {
                  Label(entry.name, systemImage: "folder")
                }
                .tint(.primary)
              case .file:
                Button {
                  filename = entry.name
                } label: {
                  Label {
                    Text(entry.name)
                  } icon: {
                    Image(systemName: "doc.text")
                  }
                }
                .tint(.primary)
              }
            }
          }
        }
      }
      .navigationTitle(navigationTitle)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          if currentPath != rootPath {
            Button {
              currentPath = (currentPath as NSString).deletingLastPathComponent
              Task { await loadEntries() }
            } label: {
              Label("Back", systemImage: "chevron.left")
            }
          } else {
            Button("Cancel") { dismiss() }
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
      filename = initialFilename
      await loadRoot()
    }
  }

  private var navigationTitle: String {
    if currentPath == rootPath {
      return "Save As"
    }
    return (currentPath as NSString).lastPathComponent
  }

  private func loadRoot() async {
    do {
      rootPath = try await Backend.shared.getRootPath()
      currentPath = rootPath
      await loadEntries()
    } catch {
      self.error = error.localizedDescription
      isLoading = false
    }
  }

  private func loadEntries() async {
    do {
      let rawEntries = try await Backend.shared.listFiles(atPath: currentPath)
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
    let path = (currentPath as NSString).appendingPathComponent(name)
    do {
      try await Backend.shared.createDirectory(atPath: path)
      await loadEntries()
    } catch {
      self.error = error.localizedDescription
    }
  }
}
