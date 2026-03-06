import AppIntents
import WidgetKit

struct ExecuteScriptIntent: AppIntent {
  static let title: LocalizedStringResource = "Run Script"
  static let description = IntentDescription("Executes a Racket script and returns its output.")

  @Parameter(title: "Script", optionsProvider: ScriptOptionsProvider())
  var script: String

  static var parameterSummary: some ParameterSummary {
    Summary("Run \(\.$script)")
  }

  func perform() async throws -> some IntentResult & ReturnsValue<String> {
    guard let root = ScriptManifest.rootPath() else {
      throw IntentError.message("No scripts available. Open the app first.")
    }
    let fullPath = (root as NSString).appendingPathComponent(script)
    let output = try await ScriptRunner.run(scriptAtPath: fullPath)
    ScriptOutputCache.save(output: output, for: script)
    WidgetCenter.shared.reloadTimelines(ofKind: ScriptOutputCache.widgetKind)
    return .result(value: output)
  }
}

private struct ScriptOptionsProvider: DynamicOptionsProvider {
  func results() async throws -> [String] {
    ScriptManifest.scripts()
  }
}

private enum IntentError: Swift.Error, CustomLocalizedStringResourceConvertible {
  case message(String)

  var localizedStringResource: LocalizedStringResource {
    switch self {
    case .message(let text):
      LocalizedStringResource(stringLiteral: text)
    }
  }
}
