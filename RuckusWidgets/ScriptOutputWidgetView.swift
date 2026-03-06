import SwiftUI

struct ScriptOutputWidgetView: View {
  let entry: ScriptEntry

  var body: some View {
    if let scriptId = entry.scriptId {
      VStack(alignment: .leading, spacing: 4) {
        HStack {
          Text((scriptId as NSString).deletingPathExtension)
            .font(.caption.bold())
            .lineLimit(1)
          Spacer()
          refreshLink(for: scriptId)
        }
        Text(entry.output)
          .font(.system(.caption2, design: .monospaced))
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      }
      .padding()
    } else {
      Text("Select a script")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }

  private func refreshLink(for scriptId: String) -> some View {
    let encoded = scriptId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    return Link(destination: URL(string: "ruckus://refresh?script=\(encoded)")!) {
      Image(systemName: "arrow.clockwise")
        .font(.caption)
    }
  }
}
