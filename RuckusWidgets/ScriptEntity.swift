import AppIntents

struct ScriptEntity: AppEntity {
  static let typeDisplayRepresentation: TypeDisplayRepresentation = "Script"
  static let defaultQuery = ScriptEntityQuery()

  var id: String
  var name: String

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(name)")
  }
}
