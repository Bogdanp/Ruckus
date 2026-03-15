# Implement Folder Deletion

## Summary

The file browser supports swipe-to-delete for individual files but not for
folders. Users who create a folder by mistake or want to clean up their
workspace have no way to remove it from within the app.

## Affected Code

### `ruckus-core/filesystem.rkt:68-72`

```racket
(define-rpc (create-directory [at-path path : String])
  (make-directory* path))

(define-rpc (delete-file [at-path path : String])
  (base:delete-file path))
```

There is an RPC for creating directories and deleting files, but no RPC for
deleting a directory (recursively or otherwise).

### `Ruckus/Views/FolderBrowser.swift:84-102`

```swift
case .folder:
  Button {
    currentDirectory = entry.path
    Task { await loadEntries() }
  } label: {
    Label(entry.name, systemImage: "folder")
  }
  .tint(.primary)
case .file:
  fileRow(entry)
    .swipeActions(edge: .trailing) {
      if allowsDeletion {
        Button(role: .destructive) {
          Task { await deleteEntry(entry) }
        } label: {
          Label("Delete", systemImage: "trash")
        }
      }
    }
```

The `.swipeActions` modifier is only attached to the `.file` case. Folders
have no swipe action and no other deletion affordance.

### `Ruckus/Views/FolderBrowser.swift:145-156`

```swift
private func deleteEntry(_ entry: BrowserEntry) async {
  do {
    try await Backend.shared.deleteFile(atPath: entry.path)
    ...
```

`deleteEntry` calls `deleteFile`, which only works on files. Passing a
directory path would fail.

## Impact

Users cannot delete folders from the file browser. The only workaround is to
use the iOS Files app to navigate to the Ruckus container and delete the
folder there.

## Suggested Fix

1. **Add a `delete-directory` RPC** in `filesystem.rkt`:

   ```racket
   (define-rpc (delete-directory [at-path path : String])
     (base:delete-directory/files path))
   ```

   `delete-directory/files` recursively removes the directory and its
   contents. Regenerate `Backend.swift` afterwards.

2. **Add a confirmation alert** for folder deletion in `FolderBrowser.swift`,
   since the operation is recursive and destructive. Present the folder name
   and a "Delete Folder" destructive button.

3. **Attach swipe actions to the `.folder` case** in the `list` method,
   gated behind `allowsDeletion` just like file deletion.

4. **Update `deleteEntry`** to branch on `entry.kind` — call `deleteFile`
   for files and `deleteDirectory` for folders.

5. **Handle manifest cleanup** — when a folder is deleted, any scripts
   inside it should be removed from `ScriptManifest`.

## Related

- None.
