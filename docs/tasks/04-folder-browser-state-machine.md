# Fix sticky error state in folder browser

## Summary

`FolderBrowser` keeps independent `isLoading`, `entries`, and `error` state,
but it never clears `error` after a later successful operation. Once a load,
create, or delete fails, the view continues rendering the error screen even if
subsequent requests succeed.

This is a small bug, but it is also a good candidate for refactoring the view
state into an explicit state machine. The current combination of parallel
flags makes it easy to introduce contradictory states like "loaded entries
exist but error still wins".

## Affected Code

### `Ruckus/Views/FolderBrowser.swift:24-34`

```swift
if isLoading {
  ProgressView()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
} else if let error {
  ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
} else if entries.isEmpty {
  ContentUnavailableView("No Files", systemImage: "doc", description: Text("Save a file to see it here."))
} else {
  list
}
```

Rendering always prioritizes `error` if it is non-`nil`.

### `Ruckus/Views/FolderBrowser.swift:118-126`

```swift
private func loadEntries() async {
  do {
    let rawEntries = try await Backend.shared.listFiles(atPath: currentDirectory)
    entries = rawEntries.toBrowserEntries()
    isLoading = false
  } catch {
    self.error = error.localizedDescription
    isLoading = false
  }
}
```

Successful loads never reset `error`.

### `Ruckus/Views/FolderBrowser.swift:129-148`

```swift
private func createFolder() async {
  // ...
  do {
    try await Backend.shared.createDirectory(atPath: path)
    await loadEntries()
  } catch {
    self.error = error.localizedDescription
  }
}

private func deleteEntry(_ entry: BrowserEntry) async {
  do {
    try await Backend.shared.deleteFile(atPath: entry.path)
    entries.removeAll { $0.id == entry.id }
    onDelete?(entry)
  } catch {
    self.error = error.localizedDescription
  }
}
```

These paths can also leave stale error state behind.

## Impact

Users can hit a transient backend or filesystem error and end up with a sheet
that looks permanently broken until they dismiss and reopen it. Internally,
the view state is harder to extend safely because state transitions are
implicit rather than modeled.

## Suggested Fix

Replace `isLoading`, `entries`, and `error` with a single enum, for example:

```swift
enum BrowserState {
  case loading
  case loaded([BrowserEntry])
  case empty
  case error(String)
}
```

Then update all async operations to transition through that enum explicitly.
If a full enum refactor feels heavy, the minimum fix is to clear `error` at
the start of each operation and after successful loads.

Add view-model level tests for:

- load failure followed by successful reload
- failed create followed by successful create
- failed delete followed by successful delete

## Related

- None.
