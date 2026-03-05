# AsyncButton Task Leak on View Destruction

## Summary

`AsyncButton` stores a `Task<Void, Never>?` in `@State` that runs the
provided async action. When the view is removed from the hierarchy (e.g.
user navigates away or the parent view conditionally removes it), the
in-flight task is not cancelled. It continues running in the background,
potentially mutating state on a view that no longer exists.

## Affected Code

### `AsyncButton.swift:18-51`

```swift
@State private var task: Task<Void, Never>?
@State private var successTask: Task<Void, any Error>?

var body: some View {
    Button(role: role) {
        task?.cancel()
        task = Task {
            running = true
            let progressTask = Task {
                try await Task.sleep(for: .milliseconds(250))
                withAnimation {
                    loading = true
                }
            }
            await action()
            guard !Task.isCancelled else { return }
            progressTask.cancel()
            withAnimation {
                loading = false
                running = false
            }
            // ... success icon logic ...
        }
    } label: { ... }
}
```

The `task` is cancelled when the button is **pressed again** (line 23), but
there is no cancellation when the view **disappears**.

Similarly, `successTask` (line 19) shows a checkmark for 1 second. If the view
disappears during that sleep, the task completes on a defunct view.

## What Goes Wrong

1. User taps a button backed by `AsyncButton` (e.g. a save or load action).
2. The async action starts — say it's a network call or backend RPC.
3. User navigates away (switches tabs, dismisses a sheet, etc.) before the
   action completes.
4. The `Task` continues running. When it completes, it calls `withAnimation`
   to update `loading` and `running` on a view that's no longer in the
   hierarchy.
5. With `@State`, SwiftUI holds the state as long as the `Task` closure
   captures `self` (through the property wrapper projections). The view's
   state allocation isn't freed until the task completes.

## Impact

- **Resource waste**: Orphaned tasks keep running. If the action involves
  backend calls, those calls continue unnecessarily.
- **State corruption**: The `action()` closure likely captures external state
  (e.g. modifying an `EditorDocument`). Those mutations continue even though
  the user has moved on.
- **Memory pressure**: The `Task` closure captures the view's state. If the
  action is long-running, this delays deallocation.

In practice, the impact is small because `AsyncButton` is currently used for
short-duration actions. But as the app grows and the component is reused for
longer operations, this becomes a real problem.

## Suggested Fix

Add an `onDisappear` modifier to cancel in-flight tasks:

```swift
var body: some View {
    Button(role: role) {
        // ... existing code ...
    } label: {
        // ... existing code ...
    }
    .disabled(options.contains(.disabledWhileRunning) && running)
    .onDisappear {
        task?.cancel()
        task = nil
        successTask?.cancel()
        successTask = nil
    }
}
```

This ensures that when the view leaves the hierarchy:
- The main action task is cancelled (the `guard !Task.isCancelled` check on
  line 33 will bail out).
- The success icon timer is cancelled.
- References are nilled out to allow deallocation.

The existing cancellation-on-re-press logic (line 23) can stay as-is since it
handles a different case (user re-taps before completion).
