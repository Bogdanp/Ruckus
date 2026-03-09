import OSLog
import SwiftUI

struct SupportView: View {
  var body: some View {
    List {
      Section {
        ShareLink(
          item: LogsExport(),
          preview: .init("logs.txt", image: Image(systemName: "doc"))
        ) {
          Label("Export Logs...", systemImage: "square.and.arrow.up.fill")
            .labelStyle(SettingsLabelStyle(backgroundColor: .accentColor))
        }
      }
    }
    .navigationTitle("Support")
    .navigationBarTitleDisplayMode(.inline)
  }
}
