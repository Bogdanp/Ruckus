---
description: >
  General coding style preferences. Always active when writing or modifying code.
alwaysApply: true
---

# Coding Style

- Only write comments when they are absolutely necessary to explain a concept
  or a behavior, not for things that you can read the code and understand.

## Swift Logging Style

- Use lower case messages with no punctuation in Logger calls.
- Prefix log messages with `\(#function):` so the call site is visible.
- Example: `Logger.backend.error("\(#function): failed to mark executor step installed: \(error)")`

## Post-Change Verification

- After modifying Swift files, always run `swiftlint lint --quiet` on the
  changed files before considering the task complete.
