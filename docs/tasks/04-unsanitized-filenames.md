# Unsanitized Filenames in Save

## Summary

When the user types a filename in the Save As sheet, it is appended directly to
a directory path without any sanitization. Filenames containing path separators
(`/`), parent-directory traversals (`..`), or other special characters can
escape the intended save directory.

## Affected Code

### `SaveBrowserSheet.swift:41-43`

```swift
Button("Save") {
    let name = filename.hasSuffix(".rkt") ? filename : filename + ".rkt"
    onSave(currentDirectory, name)
    dismiss()
}
```

The `filename` is a free-text `TextField` with no character restrictions. The
only validation is that whitespace-only names are rejected (line 47).

### `ContentView.swift:64-65`

```swift
doc.title = filename
doc.path = (directory as NSString).appendingPathComponent(filename)
```

`NSString.appendingPathComponent` does normalize some things (collapses
repeated slashes) but does **not** reject `..` components.

### `EditorStore.swift:55-56`

The same pattern exists in the implicit save path:

```swift
let filename = doc.title.hasSuffix(".rkt") ? doc.title : doc.title + ".rkt"
path = (root as NSString).appendingPathComponent(filename)
```

## Exploitation Scenario

1. User opens Save As dialog.
2. Types `../../Library/somefile` as the filename.
3. After `.rkt` suffix is appended: `../../Library/somefile.rkt`.
4. `appendingPathComponent` produces a path like:
   `/var/mobile/.../files/../../Library/somefile.rkt`
   which resolves to `/var/mobile/.../Library/somefile.rkt`.
5. The backend `save` RPC writes the file at that resolved path.

In practice, iOS sandbox restrictions limit where the app can write, so this
is mostly a correctness/robustness concern rather than a true security
vulnerability on iOS. However:

- The file could end up outside the `files/` directory, breaking session
  restore (which relies on finding `/files/` in the path — see Task 08).
- On a less sandboxed platform (macOS Catalyst, future ports), this becomes a
  real security issue.
- Filenames with special characters (null bytes, control characters, Unicode
  RTL overrides) can cause confusing UI behavior.

## Suggested Fix

Sanitize the filename before use:

```swift
private func sanitizeFilename(_ input: String) -> String {
    var name = input.trimmingCharacters(in: .whitespacesAndNewlines)

    // Remove path separators
    name = name.replacingOccurrences(of: "/", with: "-")

    // Remove parent-directory traversal
    while name.contains("..") {
        name = name.replacingOccurrences(of: "..", with: "")
    }

    // Remove control characters
    name = name.unicodeScalars.filter { !$0.properties.isDefaultIgnorableCodePoint && $0.value >= 0x20 }
        .map { String($0) }
        .joined()

    // Fallback for empty result
    if name.isEmpty || name == ".rkt" {
        name = "Untitled"
    }

    return name
}
```

Apply in `SaveBrowserSheet` before calling `onSave`, and in
`EditorStore.save(_:)` before constructing the implicit path.

Alternatively, restrict the `TextField` input with a formatter that rejects
invalid characters as they're typed.

## Related

- Task 08 (fragile session restore) — files saved outside `files/` break
  session persistence.
