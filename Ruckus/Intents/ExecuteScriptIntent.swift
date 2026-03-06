import AppIntents
import WidgetKit

struct ExecuteScriptIntent: AppIntent {
  static let title: LocalizedStringResource = "Run Script"
  static let description = IntentDescription("Executes a Racket script and returns its output.")

  @Parameter(title: "Script Path")
  var scriptPath: String

  static var parameterSummary: some ParameterSummary {
    Summary("Run script at \(\.$scriptPath)")
  }

  func perform() async throws -> some IntentResult & ReturnsValue<String> {
    let output = try await ScriptRunner.run(scriptAtPath: scriptPath)
    ScriptOutputCache.save(output: output, for: scriptPath)
    WidgetCenter.shared.reloadTimelines(ofKind: "ScriptOutputWidget")
    return .result(value: output)
  }
}
