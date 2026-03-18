# Add tests for ExecutionService and ExecutionStepper

## Summary

The execution engine — the core feature of the app — has no unit tests.
`ExecutionService` manages the full execution lifecycle (output buffering, error
handling, widget cache updates) and `ExecutionStepper` manages the async stream
of execution steps. Both are untested.

## Affected Code

### `Ruckus/Models/ExecutionService.swift`

Untested behaviors:
- Output buffering and flush to document
- Error handling during execution
- Widget cache updates via `saveWidgetCache()`
- Completion fetching via `fetchCompletions()` (includes retry logic)
- Cancellation handling

### `Ruckus/Models/ExecutionStepper.swift`

Untested behaviors:
- Async stream creation and consumption
- Signal handling
- Stream error propagation

## Impact

Changes to the execution engine cannot be validated automatically. Regressions
in output handling, cancellation, or error reporting go undetected.

## Suggested Fix

Create `RuckusTests/Models/ExecutionServiceTests.swift` and
`RuckusTests/Models/ExecutionStepperTests.swift`. Mock the Backend to test:
- Happy path: execute script, receive output steps, complete
- Error path: execution fails, error propagated to document
- Cancellation: stop mid-execution, verify cleanup
- Widget cache: verify cache is written on completion
- Completions: verify fetch and retry logic
