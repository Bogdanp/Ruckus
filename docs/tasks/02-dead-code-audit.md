# Dead Code Audit

## Summary

Audit the codebase for dead code — unused imports, unreachable functions,
parameters that are never exercised, and commented-out code — then remove it.
A quick manual scan turned up a few confirmed instances, but a thorough
file-by-file pass is needed.

## Affected Code

### `Ruckus/Views/SupportView.swift:1`

```swift
import OSLog
```

`OSLog` is imported but never used anywhere in this file (no `Logger`,
`os_log`, or `OSLog` references).

### `Ruckus/Models/EditorDocument.swift:31`

```swift
func appendOutput(_ text: String, stream: Stream, font: UIFont? = nil) {
```

The `font` parameter defaults to `nil` and every call site in the project
omits it, so it always falls through to the default. The parameter and the
nil-coalescing logic on line 35 can be removed, inlining the default font.

## Impact

Dead code increases cognitive load and makes refactors harder — it's unclear
whether unused symbols are intentionally kept for future use or simply
forgotten. Unused imports can also slow incremental builds slightly.

## Suggested Fix

1. Remove the `import OSLog` line from `SupportView.swift`.
2. Remove the `font` parameter from `appendOutput` and inline the default
   font value.
3. Perform a file-by-file audit of the Swift and Racket sources for
   additional instances: unused imports, unreferenced private
   functions/properties, and commented-out code blocks.
4. Build after each removal to confirm nothing breaks.

## Related

- None.
