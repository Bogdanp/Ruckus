# Test SaveBrowserSheet filename validation

## Summary

`SaveBrowserSheet` has 0% test coverage (152 executable lines). The
`filenameError` computed property contains filename validation logic
(slashes, "..", control characters, ignorable code points) that is the
core of the save-as UX. The save button also auto-appends `.rkt` when
missing. Both are pure string logic, easy to test by extracting into a
testable helper.

## Affected Code

### `Ruckus/Views/SaveBrowserSheet.swift:10-20`

```swift
private var filenameError: String? {
  let trimmed = filename.trimmingCharacters(in: .whitespacesAndNewlines)
  if trimmed.isEmpty { return nil }
  if trimmed.contains("/") { return "Filename cannot contain \"/\"" }
  if trimmed.contains("..") { return "Filename cannot contain \"..\"" }
  let hasControlChars = trimmed.unicodeScalars.contains {
    $0.value < 0x20 || $0.properties.isDefaultIgnorableCodePoint
  }
  if hasControlChars { return "Filename contains invalid characters" }
  return nil
}
```

### `Ruckus/Views/SaveBrowserSheet.swift:58`

```swift
let name = filename.hasSuffix(".rkt") ? filename : filename + ".rkt"
```

## Impact

Regressions in filename validation could allow saving files with
dangerous names or reject valid names.

## Suggested Fix

Extract `filenameError` logic into a static or free function (e.g.
`SaveBrowserSheet.validateFilename(_:) -> String?`) so it can be called
from tests without instantiating the SwiftUI view.

Add `RuckusTests/Views/SaveBrowserSheetTests.swift` with:

1. **Valid filename returns nil** — `"my-script"` → nil.
2. **Slash rejected** — `"a/b"` → error mentioning "/".
3. **Double-dot rejected** — `"a..b"` → error mentioning "..".
4. **Control character rejected** — `"\u{0000}test"` → error.
5. **Ignorable code point rejected** — `"\u{00AD}test"` (soft hyphen) → error.
6. **Empty after trimming returns nil** — `"  "` → nil (handled by
   disabled state, not by error message).
7. **Auto-appends .rkt** — `"script"` → `"script.rkt"`.
8. **Does not double-append** — `"script.rkt"` stays `"script.rkt"`.

## Related

- None.
