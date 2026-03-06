import WidgetKit

struct ScriptWidgetProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> ScriptEntry {
    ScriptEntry(date: .now, output: "Script output will appear here", scriptId: nil)
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
    guard let scriptId = configuration.script?.id,
          let cached = ScriptOutputCache.load(for: scriptId) else {
      return ScriptEntry(date: .now, output: "Select a script", scriptId: configuration.script?.id)
    }
    return ScriptEntry(date: cached.date, output: cached.output, scriptId: scriptId)
  }
}
