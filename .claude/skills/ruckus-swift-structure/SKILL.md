---
name: ruckus-swift-structure
description: |
  Use when creating or moving Swift files, adding extensions, or deciding
  where to place new Swift code in the project. Covers folder conventions
  and file naming.
user_invocable: false
---

# Swift Project Structure

## Extensions

Place Swift extensions in the appropriate folder:
- `Ruckus/Backend/` — extensions on auto-generated backend types (e.g. `FilesystemEntry`, `File`, `Folder`)
- `Ruckus/Extensions/` — extensions on standard library or framework types (e.g. `URL`)

Name extension files as `TypeName+Feature.swift`.

## Adding or Removing Swift Files

Tuist auto-globs all `.swift` files under `Ruckus/` and `RuckusTests/` — you
do NOT need to manually register new files in `Project.swift`. However, after
adding or removing a file you must regenerate the Xcode project:

    tuist generate --no-open

Without this step, Xcode won't see the new file and the build will fail.
