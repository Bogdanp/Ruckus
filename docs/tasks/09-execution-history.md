# Add execution history

## Summary

Each script execution replaces the previous output. There is no way to review
past runs or compare outputs between executions.

## Affected Code

### `Ruckus/Models/EditorStore.swift:124`

```swift
doc.output = NSAttributedString()
```

Output is cleared at the start of each execution.

### `Ruckus/Models/EditorDocument.swift:15`

```swift
var output = NSAttributedString()
```

Only a single output is stored per document.

## Impact

Users lose previous output when re-running a script. Comparing behavior
between runs requires manually copying output beforehand.

## Suggested Fix

1. **Store execution history** — add an array of past outputs to
   `EditorDocument`, e.g. `var outputHistory: [(date: Date, stdout: Data,
   stderr: Data)]`. Store raw bytes and lazily reconstruct
   `NSAttributedString` on display. Cap by total size (e.g. 1 MB per
   document) rather than count to avoid memory pressure on device.
2. **History UI** — add a list picker or swipe gesture in
   `OutputSheetView` to navigate between past and current output.
3. **Timestamp display** — show when each execution ran.
4. **Clear history** — provide a button to clear old entries.

## Related

- Task 10: Image rendering in output — if image output is added, history
  storage needs to accommodate image data alongside text.
