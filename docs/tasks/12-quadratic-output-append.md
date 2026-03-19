# O(n²) output append in EditorDocument

## Summary

`EditorDocument.appendOutput` copies the entire accumulated
`NSAttributedString` on every call, making total output construction
quadratic in the number of append calls.

## Affected Code

### `Ruckus/Models/EditorDocument.swift:44-47`

```swift
let mutable = NSMutableAttributedString(attributedString: output)
mutable.append(NSAttributedString(string: text, attributes: attrs))
output = mutable
```

Each call allocates a new `NSMutableAttributedString` and copies the
full contents of `output` into it before appending. For a program that
produces many lines of output, later appends copy increasingly large
strings.

## Suggested Fix

Store a private `NSMutableAttributedString` as the backing buffer and
append directly to it. Publish the immutable `output` property on a
debounced schedule or by replacing it with the current snapshot after
each execution step (the step boundary already exists in
`ExecutionService.runExecution`).

This keeps the per-step work proportional to the new text rather than
the accumulated text.

## Alternatives

- Cap output length and truncate early (loses output).
- Batch all output per step into a single append (reduces the constant
  but is still quadratic if steps are small and numerous).
