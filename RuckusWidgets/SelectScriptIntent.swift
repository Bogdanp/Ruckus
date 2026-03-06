import AppIntents

struct SelectScriptIntent: WidgetConfigurationIntent {
  static let title: LocalizedStringResource = "Select Script"
  static let description = IntentDescription("Choose a Racket script to display on the widget.")

  @Parameter(title: "Script Path")
  var scriptPath: String?
}
