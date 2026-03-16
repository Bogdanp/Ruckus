# Handle deletion of a file or folder backing an open editor tab

## Summary

When a user deletes a file (or a folder containing files) via the file
browser, any editor tabs backed by those files remain open with stale
paths. The user gets no indication that the backing file is gone. If
they later try to save, the write fails because the parent directory
(for folder deletion) or the file itself no longer exists.

## Affected Code

### `Ruckus/Views/FolderBrowser.swift` — `deleteEntry`

After a successful deletion the browser updates its own list and calls
`onDelete`, but nothing notifies `EditorStore` that the path is gone.

### `Ruckus/Models/EditorStore.swift`

`EditorStore` has no mechanism to react to external file deletions.
Saving calls `Backend.shared.save(doc.code, to: path)` which will fail
if the path or its parent directory no longer exists.

## Impact

- The tab title shows the old filename as if nothing happened.
- Edits appear to work (in-memory) but saving fails with an opaque
  Racket error.
- Folder deletion makes this especially likely — the user may not
  realize a folder contains an open file.

## Suggested Fix

When `onDelete` fires for a deleted entry, check whether any open
`EditorDocument` has a path that matches (for files) or is prefixed by
(for folders) the deleted path. For each affected document:

1. **Mark it unsaved / untitled** — clear `doc.path` and update
   `doc.title` (e.g. back to "Untitled") so the user sees the tab has
   changed.
2. **Optionally show a brief toast or banner** — "foo.rkt was deleted
   from disk" — so the user understands why the tab title changed.

This keeps the in-memory content safe (no data loss) while making it
clear the file needs to be re-saved to a new location.

### Alternative

Close affected tabs outright after prompting. This is simpler but
risks data loss if the user had unsaved edits.

## Related

- Task 29 (folder deletion) introduced the most common path to this
  bug, but single-file deletion has the same issue.
