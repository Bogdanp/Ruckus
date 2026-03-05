import Foundation
import NoiseSerde

extension [FilesystemEntry] {
  func toBrowserEntries() -> [BrowserEntry] {
    map { entry in
      switch entry {
      case .file(let file):
        BrowserEntry(
          name: (file.path as NSString).lastPathComponent,
          path: file.path,
          kind: .file(size: file.size)
        )
      case .folder(let folder):
        BrowserEntry(
          name: (folder.path as NSString).lastPathComponent,
          path: folder.path,
          kind: .folder
        )
      }
    }
    .sorted { lhs, rhs in
      if lhs.isFolder != rhs.isFolder { return lhs.isFolder }
      return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }
  }
}
