import AppIntents
import SwiftUI
import WidgetKit

struct ScriptEntry: TimelineEntry {
  let date: Date
  let output: String
  let scriptPath: String?
}

struct ScriptWidgetProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> ScriptEntry {
    ScriptEntry(date: .now, output: "Script output will appear here", scriptPath: nil)
  }

  func snapshot(for configuration: SelectScriptIntent, in context: Context) async -> ScriptEntry {
    entry(for: configuration)
  }

  func timeline(
    for configuration: SelectScriptIntent,
    in context: Context
  ) async -> Timeline<ScriptEntry> {
    Timeline(entries: [entry(for: configuration)], policy: .never)
  }

  private func entry(for configuration: SelectScriptIntent) -> ScriptEntry {
    guard let path = configuration.scriptPath,
          let cached = ScriptOutputCache.load(for: path) else {
      return ScriptEntry(date: .now, output: "Configure a script path", scriptPath: configuration.scriptPath)
    }
    return ScriptEntry(date: cached.date, output: cached.output, scriptPath: path)
  }
}

struct ScriptOutputWidgetView: View {
  let entry: ScriptEntry

  var body: some View {
    if let scriptPath = entry.scriptPath {
      VStack(alignment: .leading, spacing: 4) {
        HStack {
          Text(URL(fileURLWithPath: scriptPath).lastPathComponent)
            .font(.caption.bold())
            .lineLimit(1)
          Spacer()
          refreshLink(for: scriptPath)
        }
        Text(entry.output)
          .font(.system(.caption2, design: .monospaced))
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      }
      .padding()
    } else {
      Text("Configure a script path")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }

  private func refreshLink(for path: String) -> some View {
    let encoded = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    return Link(destination: URL(string: "ruckus://refresh?path=\(encoded)")!) {
      Image(systemName: "arrow.clockwise")
        .font(.caption)
    }
  }
}

@main
struct RuckusWidgets: Widget {
  let kind = "ScriptOutputWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind,
      intent: SelectScriptIntent.self,
      provider: ScriptWidgetProvider()
    ) { entry in
      ScriptOutputWidgetView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .configurationDisplayName("Script Output")
    .description("Displays the output of a Racket script.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}
