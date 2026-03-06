# Home Screen Widgets

## Summary

Add WidgetKit widgets that display the output of a user-configured Racket
script. A widget would periodically execute a script and render its output
on the home screen. This builds on the Shortcuts/App Intents integration
(task 15) to reuse the headless script execution path.

## Affected Code

### `Ruckus/Backend.swift:176-190`

```swift
public func executeScript(atPath path: String) async throws -> UVarint { ... }
```

The backend execution API lives in the main app process. Widget extensions
run in a separate process and cannot directly access `Backend.shared`.
The widget will need a way to execute scripts out-of-process — either by
invoking the app intent from task 15, or by running a lightweight backend
instance in the widget extension.

### `Project.swift`

The Tuist project manifest will need a new widget extension target with a
dependency on WidgetKit and the shared backend/model code.

## Impact

Without widgets, users have no way to surface script results on the home
or lock screen. Widgets would enable dashboard-style use cases — showing
computed values, status checks, or formatted text from Racket scripts
without opening the app.

## Suggested Fix

1. **Add a widget extension target** in `Project.swift` (e.g.
   `RuckusWidgets`). Include WidgetKit and SwiftUI dependencies.

2. **Create a `TimelineProvider`** that:
   - Reads the user's configured script path from a shared App Group
     container (e.g. `UserDefaults(suiteName:)`).
   - Executes the script and collects its output.
   - Returns a `TimelineEntry` containing the output string and a
     refresh date.

3. **Script execution in the extension** — two options:
   - **Preferred:** Use the `ExecuteScriptIntent` from task 15 as an
     `AppIntent`-based widget configuration (`AppIntentConfiguration`).
     This lets WidgetKit drive execution through the main app and avoids
     duplicating the backend in the extension.
   - **Alternative:** Embed a minimal backend in the extension process.
     Heavier, but avoids waking the main app.

4. **Widget UI** — a SwiftUI view that renders the script output as text.
   Support `.systemSmall`, `.systemMedium`, and `.systemLarge` families.
   Use a monospaced font to match the editor aesthetic.

5. **Configuration** — use `AppIntentConfiguration` so users pick a script
   via the widget's edit sheet. The intent parameter from task 13 can be
   reused here.

Sketch for the timeline provider using App Intents:

```swift
import WidgetKit
import SwiftUI
import AppIntents

struct ScriptEntry: TimelineEntry {
    let date: Date
    let output: String
}

struct ScriptWidgetProvider: AppIntentTimelineProvider {
    typealias Intent = SelectScriptIntent

    func timeline(for intent: SelectScriptIntent, in context: Context) async -> Timeline<ScriptEntry> {
        let output: String
        do {
            output = try await executeScript(atPath: intent.scriptPath)
        } catch {
            output = "Error: \(error.localizedDescription)"
        }
        let entry = ScriptEntry(date: .now, output: output)
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
        return Timeline(entries: [entry], policy: .after(next))
    }
}
```

## Related

- [Task 15 — Apple Shortcuts Integration](15-shortcuts-integration.md):
  prerequisite; provides the headless execution path and App Intents
  infrastructure that widgets build on.
