import SwiftUI

struct SaveBrowserSheet: View {
  var initialFilename: String
  var onSave: (String, String) -> Void
  @Environment(\.dismiss) private var dismiss
  @State private var filename = ""
  @State private var currentDirectory = ""

  var body: some View {
    FolderBrowser(
      rootTitle: "Save As",
      dismissLabel: "Cancel",
      currentDirectory: $currentDirectory,
      header: { saveHeader },
      fileRow: { entry in
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
    )
    .onAppear {
      filename = initialFilename
    }
  }

  private var saveHeader: some View {
    VStack(spacing: 0) {
      HStack {
        TextField("Filename", text: $filename)
          .textFieldStyle(.roundedBorder)
          .autocorrectionDisabled()
          .textInputAutocapitalization(.never)
        Button("Save") {
          let name = filename.hasSuffix(".rkt") ? filename : filename + ".rkt"
          onSave(currentDirectory, name)
          dismiss()
        }
        .buttonStyle(.borderedProminent)
        .disabled(filename.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
      .padding()
      Divider()
    }
  }
}
