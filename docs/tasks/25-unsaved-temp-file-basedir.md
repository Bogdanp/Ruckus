# Unsaved documents should use base dir for temp files

## Summary

When an unsaved document is executed, the backend creates a temporary file in
the system temp directory (e.g. `/tmp/ruckus-abcd1234.rkt`). The executor then
sets `current-directory` to the temp file's parent directory, which means
relative `require` paths resolve against `/tmp/` instead of the user's project
directory. If the user has saved other modules in the base directory and
references them with relative paths (e.g. `(require "utils.rkt")`), those
requires fail.

## Affected Code

### `ruckus-core/filesystem.rkt:63-66`

```racket
(define-rpc (make-temp-path : String)
  (define path (make-temporary-file "ruckus-~a.rkt"))
  (base:delete-file path)
  (path->string path))
```

`make-temporary-file` creates a path under the OS temp directory. There is no
option to specify a parent directory.

### `ruckus-core/executor.rkt:54-63`

```racket
(define (evaluate in)
  (define-values (document-dir document-name _is-dir?)
    (split-path (format "~a" (object-name in))))
  ...
  (parameterize ([current-directory document-dir])
    ...))
```

`current-directory` is derived from the file's location. For temp files this
is `/tmp/` (or the platform equivalent), not the user's working directory.

### `Ruckus/Models/EditorStore.swift:113-122`

```swift
} else {
    do {
        let tempPath = try await Backend.shared.makeTempPath()
        try await Backend.shared.save(doc.code, to: tempPath)
        doc.tempPath = tempPath
        path = tempPath
    } catch {
        ...
    }
}
```

The Swift side calls `makeTempPath()` without providing a preferred directory.

## Impact

Any unsaved document that uses a relative `require` to load a sibling module
fails with a "file not found" error, even though the module exists in the base
directory. This is confusing because the same code works fine once the document
is saved to disk next to the required module.

## Suggested Fix

Pass the base directory to `make-temp-path` so that the temp file is created
inside it:

1. **Add a `base-dir` parameter to `make-temp-path`** in `filesystem.rkt`:

   ```racket
   (define-rpc (make-temp-path [in-dir dir : String] : String)
     (define path (make-temporary-file "~a.rkt" #f dir))
     (base:delete-file path)
     (path->string path))
   ```

2. **Update the Swift call site** in `EditorStore.swift` to pass the base
   directory (from the app's current working directory or a sensible default):

   ```swift
   let baseDir = baseDirectory ?? NSTemporaryDirectory()
   let tempPath = try await Backend.shared.makeTempPath(inDir: baseDir)
   ```

3. **Ensure cleanup still works.** The existing `cleanupTempFile()` deletes by
   full path, so moving the temp file location should not break cleanup.

Use a dotfile name pattern (e.g. `.ruckus-XXXX.rkt`) to keep temp files from
cluttering the user's project directory.

## Related

- None
