---
description: >
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

## Swift Logging Style

- Use lower case messages with no punctuation in Logger calls.
- Prefix log messages with `\(#function):` so the call site is visible.
- Example: `Logger.backend.error("\(#function): failed to mark executor step installed: \(error)")`

## Post-Change Verification

- After modifying Swift files, always run `swiftlint lint --quiet` on the
  changed files before considering the task complete.
