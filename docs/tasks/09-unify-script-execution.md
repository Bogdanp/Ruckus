# Unify Script Execution Between ScriptRunner and AppDelegate

## Summary

There are two independent implementations of the "execute script and collect
output" flow: `ScriptRunner.run()` (used by Shortcuts/widgets) and the
`EditorStore.execute()` → `AppDelegate.step()` path (used by the editor).
They share the same backend RPCs but duplicate the polling loop, output
accumulation, and step-switching logic.

## Affected Code

### `ScriptRunner.swift:4-26`

```swift
enum ScriptRunner {
  static func run(scriptAtPath path: String) async throws -> String {
    let id = try await Backend.shared.executeScript(atPath: path)
    var stdout = ""
    while true {
      let step = try await Backend.shared.stepExecution(id)
      let output: ExecutionOutput
      let isDone: Bool
      switch step {
      case .done(let value):
        output = value
        isDone = true
      case .more(let value):
        output = value
        isDone = false
      }
      if let text = String(data: output.stdout, encoding: .utf8) {
        stdout += text
      }
      if isDone { break }
    }
    return stdout
  }
}
```

### `AppDelegate.swift:74-123`

```swift
static func step(_ executionId: UInt64) {
  ...
  let step = try await Backend.shared.stepExecution(executionId)
  let output: ExecutionOutput
  let isDone: Bool
  switch step {
  case .done(let value):
    output = value
    isDone = true
  case .more(let value):
    output = value
    isDone = false
  }
  ...
}
```

The `switch step` → extract `output` and `isDone` pattern is identical in
both places.

## Impact

- Bug fixes to the polling logic must be applied in two places.
- `ScriptRunner` doesn't use `OutputBuffer` for UTF-8 decoding, so it can
  produce garbled output if a multi-byte character is split across steps.
- `ScriptRunner` silently discards stderr, which may confuse widget users
  when a script fails with no output.

## Suggested Fix

Extract the step-result destructuring into a method or computed properties
on `ExecutionStep`:

```swift
extension ExecutionStep {
  var output: ExecutionOutput {
    switch self {
    case .done(let v), .more(let v): return v
    }
  }

  var isDone: Bool {
    if case .done = self { return true }
    return false
  }
}
```

This eliminates the duplicated switch in both call sites. For deeper
unification, consider a shared async function that handles the polling loop:

```swift
func collectOutput(executionId: UInt64) -> AsyncThrowingStream<(ExecutionOutput, Bool), Error>
```

Both `AppDelegate.step()` and `ScriptRunner.run()` could consume this stream,
applying their own output handling (incremental UI updates vs. string
accumulation).

## Related

- None.
