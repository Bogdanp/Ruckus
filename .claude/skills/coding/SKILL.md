---
description: |
  General coding style preferences. Always active when writing or modifying code.
---

# Coding Style

- Only write comments when they are absolutely necessary to explain a concept
  or a behavior, not for things that you can read the code and understand.
- It's OK to use empty lines to separate logical blocks of code, but
  avoid unnecessary empty lines otherwise.
- Simplify boolean expressions, avoid pleonasms line
  `#expect(expression == true)` or `#expect(expression == false)`.

## Racket

- When a procedure has many positional arguments, you can use symbol
  comments as a poor man's keywords. For example, instead of `(File p
  s)` you can write `(File #;path p #;size s)`.

## Swift Project Structure

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

## Swift Logging Style

- Use lower case messages with no punctuation in Logger calls.
- Prefix log messages with `\(#function):` so the call site is visible.
- Example: `Logger.backend.error("\(#function): failed to mark executor step installed: \(error)")`

## Post-Change Verification

- After modifying Swift files, always run `swiftlint lint --quiet` on the
  changed files before considering the task complete.
