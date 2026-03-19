import AppIntents

struct ExecuteScriptIntent: AppIntent {
  static let title: LocalizedStringResource = "Run Script"
  static let description = IntentDescription("Executes a Racket script and returns its output.")

  @Parameter(title: "Script", optionsProvider: ScriptOptionsProvider())
  var script: String

  static let openAppWhenRun = true

  static var parameterSummary: some ParameterSummary {
    Summary("Run \(\.$script)")
  }

  @MainActor
  func perform() async throws -> some IntentResult & ReturnsValue<String> {
    guard let root = ScriptManifest.rootPath() else {
      throw IntentError.message("No scripts available. Open the app first.")
    }
    let fullPath = root.appendingPathComponent(script)
    let store = EditorStore.shared
    try await store.open(path: fullPath)
    guard let doc = store.activeDocument else {
      throw IntentError.message("Failed to open script.")
    }
    await store.execute()
    guard let executionId = doc.executionId else {
      throw IntentError.message("Failed to start script execution.")
    }
    let result = try await ExecutionRegistry.shared.awaitCompletion(of: executionId)
    switch result {
    case .completed:
      break
    case .stopped:
      throw IntentError.message("Script execution was stopped.")
    case .failed(let error):
      throw IntentError.message("Script failed: \(error.localizedDescription)")
    }
    let output = doc.output.string
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
