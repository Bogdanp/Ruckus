import NoiseSerde
import SwiftUI

struct FileBrowserSheet: View {
  var onOpen: (String) -> Void
  @Environment(\.dismiss) private var dismiss
  @State private var currentDirectory = ""

  var body: some View {
    FolderBrowser(
      rootTitle: "Files",
      dismissLabel: "Done",
      allowsDeletion: true,
      onDelete: { entry in
        if case .file = entry.kind {
          ScriptManifest.remove(script: entry.name)
        }
      },
      currentDirectory: $currentDirectory,
      header: { EmptyView() },
      fileRow: { entry in
        if case .file(let size) = entry.kind {
          Button {
            onOpen(entry.path)
            dismiss()
          } label: {
            Label {
              HStack {
                Text(entry.name)
                Spacer()
                Text(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            } icon: {
              Image(systemName: "doc.text")
            }
          }
          .tint(.primary)
        }
      }
    )
  }
}

enum BrowserEntryKind {
  case file(size: UVarint)
  case folder
}

struct BrowserEntry: Identifiable {
  let name: String
  let path: String
  let kind: BrowserEntryKind
  var id: String { path }

  var isFolder: Bool {
    if case .folder = kind { return true }
    return false
  }
}
