# Adopt AsyncButton across the app

## Summary

`AsyncButton` is defined in `Ruckus/Views/AsyncButton.swift` but never
actually used in the app. Several places in `ContentView` and
`FolderBrowser` wrap async calls in `Button { Task { await ... } }` — the
exact pattern `AsyncButton` was built to replace. These ad-hoc wrappers
miss the progress indicator, disabled-while-running guard, and automatic
task cancellation on disappear that `AsyncButton` provides.

## Affected Code

### `ContentView.swift:129-134`

```swift
Button {
  Task { await store.revert() }
} label: {
  Label("Revert", systemImage: "arrow.counterclockwise")
}
```

Revert is a backend RPC call that can take noticeable time. Should use
`AsyncButton` so the button disables while running.

### `ContentView.swift:142-148`

```swift
Button {
  Task { await store.formatActiveDocument() }
} label: {
  Label("Format", systemImage: "text.alignleft")
}
```

Format calls the backend formatter. Same issue — no disable-while-running
and no progress feedback.

### `ContentView.swift:188-193`

```swift
Button {
  Task { await store.stopExecution() }
} label: {
  Label("Stop", systemImage: "stop.fill")
}
```

Stop sends an RPC to halt execution. Could benefit from
`disabledWhileRunning` to prevent double-taps.

### `ContentView.swift:195-196`

```swift
Button {
  Task { await store.execute() }
```

The Run button. A primary candidate — `showsProgressView` would give
visual feedback during the save+execute pipeline.

### `FolderBrowser.swift:55-60`

```swift
Button {
  currentDirectory = (currentDirectory as NSString).deletingLastPathComponent
  Task { await loadEntries() }
} label: {
  Label("Back", systemImage: "chevron.left")
}
```

Back button loads entries from the backend. Could show progress on slow
file listings.

### `FolderBrowser.swift:79-82`

```swift
Button("Delete Folder", role: .destructive) {
  onCloseDocuments?(folder)
  Task { await deleteEntry(folder) }
}
```

Delete operations call backend RPCs. Same pattern in lines 96-98 for file
deletion and 106-108 for folder creation.

### `FolderBrowser.swift:121-126`

```swift
Button {
  currentDirectory = entry.path
  Task { await loadEntries() }
} label: {
  Label(entry.name, systemImage: "folder")
}
```

Folder navigation in the file list. Same `Button + Task` pattern.

## Impact

Users get no progress feedback and no double-tap protection on any
async button in the app. The Run and Format buttons are most noticeable
since their backend calls can take over a second.

## Suggested Fix

Replace each `Button { Task { await ... } }` with `AsyncButton`. Choose
options per-button:

- **Run/Format/Revert**: `.disabledWhileRunning`, `.showsProgressView`
- **Stop**: `.disabledWhileRunning` only (should feel instant)
- **Delete/Create folder**: `.disabledWhileRunning` only
- **Folder navigation**: `.disabledWhileRunning` only (progress flash
  would be distracting for fast navigations)

Note that `AsyncButton` currently takes `() async -> Void` with no
throwing support. Some call sites may need the action signature to be
relaxed, or errors should be handled inside the closure.

## Related

- None
