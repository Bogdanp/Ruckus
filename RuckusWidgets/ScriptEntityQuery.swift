import AppIntents

struct ScriptEntityQuery: EntityStringQuery {
  func entities(for identifiers: [String]) async throws -> [ScriptEntity] {
    let all = allScripts()
    return all.filter { identifiers.contains($0.id) }
  }

  func entities(matching string: String) async throws -> [ScriptEntity] {
    let all = allScripts()
    guard !string.isEmpty else { return all }
    return all.filter { $0.name.localizedCaseInsensitiveContains(string) }
  }

  func suggestedEntities() async throws -> [ScriptEntity] {
    allScripts()
  }

  private func allScripts() -> [ScriptEntity] {
    ScriptManifest.scripts().map { path in
      let name = (path as NSString).deletingPathExtension
      return ScriptEntity(id: path, name: name)
    }
  }
}
