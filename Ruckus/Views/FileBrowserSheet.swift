import SwiftUI

struct FileBrowserSheet: View {
  var onOpen: (String) -> Void
  @Environment(\.dismiss) private var dismiss
  @State private var files: [FileItem] = []
  @State private var isLoading = true
  @State private var error: String?

  var body: some View {
    NavigationStack {
      Group {
        if isLoading {
          ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error {
          ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
        } else if files.isEmpty {
          ContentUnavailableView("No Files", systemImage: "doc", description: Text("Save a file to see it here."))
        } else {
          List(files) { file in
            Button {
              onOpen(file.path)
              dismiss()
            } label: {
              Label {
                HStack {
                  Text(file.name)
                  Spacer()
                  Text(file.formattedSize)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
              } icon: {
                Image(systemName: "doc.text")
              }
            }
            .tint(.primary)
            .swipeActions(edge: .trailing) {
              Button(role: .destructive) {
                Task { await deleteFile(file) }
              } label: {
                Label("Delete", systemImage: "trash")
              }
            }
          }
        }
      }
      .navigationTitle("Files")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Done") { dismiss() }
        }
      }
    }
    .task {
      await loadFiles()
    }
  }

  private func deleteFile(_ file: FileItem) async {
    do {
      try await Backend.shared.deleteFile(atPath: file.path)
      files.removeAll { $0.id == file.id }
    } catch {
      self.error = error.localizedDescription
    }
  }

  private func loadFiles() async {
    do {
      let root = try await Backend.shared.getRootPath()
      let entries = try await Backend.shared.listFiles(atPath: root)
      files = entries.compactMap { entry in
        switch entry {
        case .file(let file):
          let name = (file.path as NSString).lastPathComponent
          return FileItem(name: name, path: file.path, size: file.size)
        case .folder:
          return nil
        }
      }
      isLoading = false
    } catch {
      self.error = error.localizedDescription
      isLoading = false
    }
  }
}

private struct FileItem: Identifiable {
  let name: String
  let path: String
  let size: UInt64
  var id: String { path }

  var formattedSize: String {
    ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
  }
}
