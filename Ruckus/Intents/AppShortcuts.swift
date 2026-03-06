import AppIntents

struct RuckusShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: ExecuteScriptIntent(),
      phrases: [
        "Run script with \(.applicationName)",
        "Execute script in \(.applicationName)"
      ],
      shortTitle: "Run Script",
      systemImageName: "play.fill"
    )
  }
}
