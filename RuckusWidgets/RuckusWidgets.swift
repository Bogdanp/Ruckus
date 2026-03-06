import SwiftUI
import WidgetKit

@main
struct RuckusWidgets: Widget {
  let kind = ScriptOutputCache.widgetKind

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
