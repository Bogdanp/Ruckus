import SwiftUI

struct EditorSettingsView: View {
  @Environment(EditorSettings.self) private var settings

  var body: some View {
    @Bindable var settings = settings
    List {
      Section("Font") {
        Stepper(
          "Size: \(Int(settings.fontSize))",
          value: $settings.fontSize,
          in: 10...30,
          step: 1
        )
        Picker("Family", selection: $settings.fontName) {
          Text("System Monospace").tag("")
          ForEach(EditorSettings.monospaceFamilies, id: \.self) { family in
            Text(family).tag(family)
          }
        }
      }

      Section {
        Text("The quick brown fox\njumps over the lazy dog")
          .font(Font(settings.font))
          .frame(maxWidth: .infinity, alignment: .leading)
      } header: {
        Text("Preview")
      }
    }
    .navigationTitle("Editor")
  }
}
