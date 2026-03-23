# Test EditorDocument output buffering

## Summary

`EditorDocument.appendOutput`, `clearOutput`, and `hasUnseenOutput` are
exercised indirectly by other tests but have no dedicated coverage for
their buffering and flush behavior. The `scheduleFlush` / `cancelFlush`
coalescing logic and the `outputVersion` counter are untested.

## Affected Code

### `Models/EditorDocument.swift:49-92`

```swift
func appendOutput(_ text: String, stream: Stream) {
    let color: UIColor = switch stream {
    case .stdout: .label
    case .stderr: .systemRed
    }
    let outputFont = UIFont.monospacedSystemFont(ofSize: UIFont.smallSystemFontSize, weight: .regular)
    let attrs: [NSAttributedString.Key: Any] = [
        .foregroundColor: color,
        .font: outputFont
    ]
    let wasEmpty = output.length == 0
    output.append(NSAttributedString(string: text, attributes: attrs))
    if wasEmpty {
        hasUnseenOutput = true
    }
    scheduleFlush()
}

func clearOutput() {
    cancelFlush()
    let range = NSRange(location: 0, length: output.length)
    output.deleteCharacters(in: range)
    notifyOutputChanged()
}
```

## Impact

The flush coalescing controls how often the UI re-renders. If broken,
output could stop updating or update excessively.

## Suggested Fix

Add `EditorDocumentOutputTests`:

1. `appendOutput` with `.stdout` sets text color to `.label`.
2. `appendOutput` with `.stderr` sets text color to `.systemRed`.
3. `hasUnseenOutput` is set to `true` only on the first append (when
   output was empty), not on subsequent appends.
4. `clearOutput` resets `output.length` to 0.
5. `outputVersion` increments after `clearOutput`.
6. `outputVersion` increments after flush (wait ~20ms for the scheduled
   flush task to fire).
7. `hasOutput` returns false initially, true after append, false after
   clear.

## Related

- None
