import SwiftUI

struct EditorSettingsView: View {
  @Environment(EditorSettings.self) private var settings

  var body: some View {
    @Bindable var settings = settings
    List {
      Section("Theme") {
        Picker("Color Theme", selection: $settings.themeName) {
          ForEach(ColorThemeName.allCases) { theme in
            Text(theme.rawValue).tag(theme)
          }
        }
      }

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

      Section("Preview") {
        ThemePreviewView(font: settings.font, palette: settings.colorPalette)
          .frame(height: 280)
          .clipShape(RoundedRectangle(cornerRadius: 8))
          .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
      }
    }
    .navigationTitle("Editor")
    .navigationBarTitleDisplayMode(.inline)
  }
}
