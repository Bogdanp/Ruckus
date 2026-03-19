# Cache scanned identifiers in CompletionController

## Summary

`CompletionController.updatePopover` calls `scanIdentifiers(in: text)`
on every text change, scanning the entire document character-by-character
to extract identifiers. For large files this adds latency to every
keystroke.

## Affected Code

### `Ruckus/Views/Editor/CompletionController.swift:50`

```swift
for item in scanIdentifiers(in: text) where item.hasPrefix(prefix) && item != prefix {
```

### `Ruckus/Views/Editor/CompletionController.swift:85-103`

The `scanIdentifiers` method iterates every character in the document.

## Suggested Fix

Cache the set of scanned identifiers and invalidate on text changes.
Options:

1. **Dirty flag + lazy recompute**: Mark a dirty flag in `updatePopover`
   and only re-scan when the flag is set and a prefix is non-empty.
   Since `scanIdentifiers` returns a `Set`, the result can be reused
   across keystrokes within the same word.

2. **Limit scan window**: Only scan a window around the cursor (e.g.
   visible lines ± buffer) instead of the full document.

3. **Debounced background scan**: Run the scan after a short idle period
   rather than synchronously on every keystroke.
