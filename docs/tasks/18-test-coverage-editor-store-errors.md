# Add tests for EditorStore error paths

## Summary

`EditorStore` has tests for its happy paths but none of its error paths are
tested — file read failures, save failures, execution failures, and partial
session restoration.

## Affected Code

### `Ruckus/Models/EditorStore.swift`

Untested error paths:
- `open()`: Backend.readFile() failure (file doesn't exist, permission denied)
- `save()`: Backend.save() failure, invalid filename containing `/` or `..`
- `execute()`: Backend.makeTempPath() or executeScript() failure
- `restoreSession()`: Some documents fail to restore while others succeed
- `revert()`: File has been deleted on disk since last save
- `importFile()`: Invalid path or permission error

### `RuckusTests/Models/EditorStoreTests.swift`

The existing `cleanupTempFile` test is weak — it doesn't verify
`Backend.deleteFile` is called or handle deletion errors.

## Impact

Error handling code is untested and may silently fail, lose data, or crash.

## Suggested Fix

Add error-path tests to `EditorStoreTests`. Inject a mock Backend that returns
errors for specific operations. Verify that errors are surfaced to the user
(via document output or alerts) and that state remains consistent after failures.
