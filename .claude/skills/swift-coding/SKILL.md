---
description: |
  Swift coding conventions and project structure. Use when writing or modifying
  Swift files.
user-invocable: false
---

# Coding Style

## Project Structure

### Extensions

Place Swift extensions in the appropriate folder:
- `Ruckus/Backend/` — extensions on auto-generated backend types (e.g. `FilesystemEntry`, `File`, `Folder`)
- `Ruckus/Extensions/` — extensions on standard library or framework types (e.g. `URL`)

Name extension files as `TypeName+Feature.swift`.

### Adding or Removing Swift Files

Tuist auto-globs all `.swift` files under `Ruckus/` and `RuckusTests/` — you
do NOT need to manually register new files in `Project.swift`. However, after
adding or removing a file you must regenerate the Xcode project:

    tuist generate --no-open

Without this step, Xcode won't see the new file and the build will fail.

## Logging Style

- Use lower case messages with no punctuation in Logger calls.
- Prefix log messages with `\(#function):` so the call site is visible.
- Example: `Logger.backend.error("\(#function): failed to mark executor step installed: \(error)")`

## Testing

- `Backend.shared` runs Racket completely in-process (embedded via Noise RPC).
  It works in unit tests without mocking — call Backend methods directly.
  Do not inject closures, create protocols, or skip testing Backend-dependent
  code paths.

## Post-Change Verification

- After modifying Swift files, always run `swiftlint lint --quiet` on the
  changed files before considering the task complete.
