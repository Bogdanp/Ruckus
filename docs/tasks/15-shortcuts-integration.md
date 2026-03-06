# Apple Shortcuts Integration

## Summary

Ruckus should integrate with Apple Shortcuts so users can create shortcuts
that execute Racket scripts. This would allow automating script execution
from the home screen, Siri, or other apps via the Shortcuts app.

## Affected Code

### `Ruckus/Models/EditorStore.swift:85-108`

```swift
func execute() async {
    guard let doc = activeDocument else { return }
    if doc.isDirty {
        // ... save logic
    }
    // ... resolve path, then execute via Backend
}
```

The current execution flow is tightly coupled to the editor UI (requires
an active document). Shortcuts integration needs a way to execute a script
by path without going through the editor.

### `Ruckus/Backend.swift:176-190`

```swift
public func executeScript(atPath path: String) -> Future<String, UVarint> { ... }
public func executeScript(atPath path: String) async throws -> UVarint { ... }
```

The backend already supports executing a script by path, which is the
right entry point for a Shortcuts action.

## Impact

Without Shortcuts integration, users cannot automate script execution or
trigger scripts from outside the app. This limits Ruckus to manual,
in-app usage only.

## Suggested Fix

Add an App Intent using the App Intents framework (iOS 16+):

1. **Create `ExecuteScriptIntent`** — an `AppIntent` that takes a script
   file path as a parameter and calls `Backend.shared.executeScript(atPath:)`.
   The intent should wait for execution to complete and return the output.

2. **Use `AppShortcutsProvider`** to register the intent so it appears in
   the Shortcuts app with a phrase like "Run script with Ruckus".

3. **Parameter options** — consider supporting:
   - A file path string parameter for the script to run.
   - An `IntentFile` parameter as an alternative so users can pick a script
     from the file picker in Shortcuts.
   - An optional string parameter for arguments/input to pass to the script.

4. **Return value** — the intent should return the script's output as a
   string so it can be piped into subsequent Shortcuts actions.

5. **Error handling** — surface execution errors as intent errors so
   Shortcuts can branch on success/failure.

Sketch:

```swift
import AppIntents

struct ExecuteScriptIntent: AppIntent {
    static var title: LocalizedStringResource = "Run Script"
    static var description = IntentDescription("Executes a Racket script in Ruckus.")

    @Parameter(title: "Script Path")
    var scriptPath: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let executionId = try await Backend.shared.executeScript(atPath: scriptPath)
        // Step through execution to completion and collect output
        let output = try await drainExecution(executionId)
        return .result(value: output)
    }
}
```

## Related

- The `step-execution` and `stop-execution` RPC methods in
  `ruckus-core/executor.rkt` will be needed to drive execution to
  completion from the intent.
