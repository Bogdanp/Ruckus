import SwiftUI

struct SaveBrowserSheet: View {
  var initialFilename: String
  var onSave: (String, String) -> Void
  @Environment(\.dismiss) private var dismiss
  @State private var filename = ""
  @State private var currentDirectory = ""

  private var filenameError: String? {
    let trimmed = filename.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty { return nil } // handled by disabled state
    if trimmed.contains("/") { return "Filename cannot contain \"/\"" }
    if trimmed.contains("..") { return "Filename cannot contain \"..\"" }
    let hasControlChars = trimmed.unicodeScalars.contains {
      $0.value < 0x20 || $0.properties.isDefaultIgnorableCodePoint
    }
    if hasControlChars { return "Filename contains invalid characters" }
    return nil
  }

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
          .overlay(
            RoundedRectangle(cornerRadius: 6)
              .stroke(filenameError != nil ? Color.red : Color.clear, lineWidth: 1)
          )
        Button("Save") {
          let name = filename.hasSuffix(".rkt") ? filename : filename + ".rkt"
          onSave(currentDirectory, name)
          dismiss()
        }
        .buttonStyle(.borderedProminent)
        .disabled(filename.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || filenameError != nil)
      }
      .padding()
      Text(filenameError ?? " ")
        .font(.caption)
        .foregroundStyle(.red)
        .padding(.horizontal)
        .padding(.bottom, 4)
        .opacity(filenameError != nil ? 1 : 0)
      Divider()
    }
  }
}
