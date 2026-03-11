# Add split view for editor and output

## Summary

The editor and output are in separate views — the output appears in a modal
sheet that covers the editor. On iPad, there is enough screen space to show
both side by side or in a top/bottom split.

## Affected Code

### `Ruckus/Views/ContentView.swift:47-66`

```swift
.sheet(item: $activeSheet) { sheet in
  switch sheet {
  case .output:
    if let doc = store.activeDocument {
      OutputSheetView(text: doc.output)
    }
  // ...
  }
}
```

Output is presented as a modal sheet.

### `Ruckus/Views/ContentView.swift:67-70`

```swift
.onChange(of: store.activeDocument?.hasUnseenOutput) { _, new in
  guard new == true else { return }
  store.activeDocument?.hasUnseenOutput = false
  activeSheet = .output
}
```

New output automatically opens the modal sheet.

## Impact

On iPad, users must constantly dismiss and re-present the output sheet while
iterating. The modal presentation interrupts the editing flow.

## Suggested Fix

1. **Adaptive layout** — in regular horizontal size class, show a split view
   with the editor on top/left and output on the bottom/right. In compact
   horizontal size class, keep the current sheet behavior. (Large iPhones
   in landscape have regular size class and would also get the split, which
   is fine.)
2. **Resizable divider** — let users drag the split point to allocate more
   space to editor or output.
3. **Toggle** — keep the output toolbar button, but have it toggle the split
   pane visibility rather than presenting a sheet.
4. **Live output** — in split mode, output streams in real-time alongside the
   editor without any modal interruption.
