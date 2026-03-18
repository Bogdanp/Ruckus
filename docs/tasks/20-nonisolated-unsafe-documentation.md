# Document nonisolated(unsafe) usage in DocumentObserver

## Summary

`DocumentObserver` uses `nonisolated(unsafe)` to pass values into
`withObservationTracking`'s `onChange` closure, which requires `@Sendable`. The
generation counter mechanism makes this safe, but the invariants are subtle and
undocumented.

## Affected Code

### `Views/Editor/DocumentObserver.swift:16-17`

```swift
nonisolated(unsafe) let document = document
nonisolated(unsafe) weak let weakDocument = document
```

These are needed because `withObservationTracking`'s `onChange` closure is
`@Sendable`, but `EditorDocument` is `@MainActor`-isolated. The safety relies
on:

1. The `generation` counter increments on every document switch (line 7).
2. The `onChange` closure checks `self.generation == expectedGeneration` before
   accessing the document (line 23).
3. `weakDocument` prevents a retain cycle if the document is deallocated.

## Impact

Without documentation, a future contributor may not understand why
`nonisolated(unsafe)` is used or may break the generation-counter invariant,
introducing a data race.

## Suggested Fix

Add a comment block above lines 16-17 explaining:
- Why `nonisolated(unsafe)` is required (Sendable closure boundary)
- Why it's safe (generation counter ensures stale closures exit immediately)
- What would break if the invariant were violated
