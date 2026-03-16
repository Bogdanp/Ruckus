# Support rearranging tabs via drag and drop

## Summary

The tab bar displays open documents in a fixed order (the order they were
opened). There is no way to rearrange tabs — users who want related files
next to each other must close and re-open them in the desired order.

## Affected Code

### `Ruckus/Views/TabBar.swift:13-23`

```swift
HStack(spacing: 6) {
  ForEach(documents) { doc in
    TabBarItem(
      title: doc.title,
      isDirty: doc.isDirty,
      isActive: doc.id == activeDocumentID,
      onSelect: { onSelect(doc) },
      onClose: { onClose(doc) }
    )
    .id(doc.id)
  }
```

The `ForEach` iterates `documents` in order but has no drag-and-drop
support. `TabBarItem` is not draggable and there is no drop target.

### `Ruckus/Models/EditorStore.swift:15`

```swift
private(set) var documents: [EditorDocument] = []
```

`documents` is `private(set)`, so `TabBar` cannot reorder the array
directly. `EditorStore` has no method to move a document from one index
to another.

## Impact

Users cannot organise their tabs. With many open files this makes it
hard to keep related files adjacent.

## Suggested Fix

1. **Add a `moveDocument(from:to:)` method** on `EditorStore`:

   ```swift
   func moveDocument(fromOffsets source: IndexSet, toOffset destination: Int) {
     documents.move(fromOffsets: source, toOffset: destination)
     saveSession()
   }
   ```

2. **Add an `onMove` callback** to `TabBar` and wire it to the store.

3. **Make `TabBarItem` draggable** using `.draggable(doc.id.uuidString)`
   and add `.dropDestination` on each item to handle reordering. Use
   `onMove` to commit the new order.

4. **Persist the new order** — `saveSession()` already serialises
   `documents` in array order, so calling it after the move is
   sufficient.

### Alternative

Use `.onMove` with `List` instead of `HStack` + `ForEach` to get
built-in reordering, but this would change the horizontal scrolling
layout and visual style significantly.

## Related

- None.
