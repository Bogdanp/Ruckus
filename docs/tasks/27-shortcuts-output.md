# Return script output to Shortcuts for use in automations

## Summary

The `ExecuteScriptIntent` already returns `doc.output.string` via
`ReturnsValue<String>`, but it sets `openAppWhenRun = true`, which forces the
app to the foreground every time. This makes the intent unsuitable for
background automations — users cannot chain the output into subsequent
Shortcuts actions without the app taking focus and interrupting the flow.

Users should be able to run a script from Shortcuts, receive its stdout as a
result, and feed it into the next action without Ruckus ever coming to the
foreground.

## Affected Code

### `Ruckus/Intents/ExecuteScriptIntent.swift:10`

```swift
static let openAppWhenRun = true
```

This forces the app to open, preventing background execution. The intent
cannot be used silently in an automation.

### `Ruckus/Intents/ExecuteScriptIntent.swift:22-29`

```swift
let store = EditorStore.shared
try await store.open(path: fullPath)
guard let doc = store.activeDocument else {
  throw IntentError.message("Failed to open script.")
}
await store.execute()
guard let executionId = doc.executionId else {
  throw IntentError.message("Failed to start script execution.")
}
```

The execution pipeline is coupled to `EditorStore` and `EditorDocument`,
which are UI-layer objects. Running in the background requires either making
these work headlessly or introducing a lighter execution path that talks to
the backend directly without going through the editor UI.

## Impact

Users who build Shortcuts automations (e.g. run a Racket script on a
schedule, pipe output to a notification or file) cannot use the intent
because it always foregrounds the app. The returned output value is
effectively inaccessible in typical automation workflows.

## Suggested Fix

### 1. Set `openAppWhenRun = false`

This is the minimum change. It tells Shortcuts the intent can run in the
background.

### 2. Add a headless execution path

The current `perform()` goes through `EditorStore.open` → `store.execute()`
→ `ExecutionRegistry.awaitCompletion`, which modifies UI state (active
document, output attributed string, etc.). For background execution, add a
lightweight path that:

1. Boots the backend if needed (it may already be running).
2. Calls `Backend.shared.executeScript(atPath:)` directly.
3. Collects stdout/stderr via `ExecutionStepper` and `OutputBuffer` without
   routing through `EditorDocument.appendOutput`.
4. Returns the plain-text output.

This avoids touching `EditorStore`, `EditorDocument`, or any `@MainActor`
UI state.

### 3. Provide the result with a dialog

Use `ReturnsValue<String> & ProvidesDialog` so that when the intent is run
interactively (e.g. from the Shortcuts app or Siri) the user sees the output
in a confirmation dialog, while background automations just receive the
string value silently.

```swift
func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
  // ...
  return .result(value: output, dialog: IntentDialog(stringLiteral: output))
}
```

## Related

- None.
