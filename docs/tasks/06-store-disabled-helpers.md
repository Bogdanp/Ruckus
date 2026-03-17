# Add computed properties on EditorStore for menu disabled states

## Summary

Menu items and toolbar buttons check `store.activeDocument?.canRevert`,
`store.activeDocument?.hasOutput`, `store.activeDocument == nil`, etc.
repeatedly. Adding computed properties on `EditorStore` that fold in the
nil check would simplify call sites.

## Affected Code

### `AppCommands.swift`

```swift
.disabled(saveAction == nil || store.activeDocument == nil)
.disabled(store.activeDocument?.canRevert != true)
.disabled(store.activeDocument?.hasOutput != true)
.disabled(store.activeDocument == nil || store.activeDocument?.isEvaluating == true)
.disabled(store.activeDocument?.isEvaluating != true)
```

### `ContentView.swift`

```swift
.disabled(store.activeDocument == nil)
.disabled(store.activeDocument?.canRevert != true)
.disabled(store.activeDocument?.hasOutput != true)
```

## Suggested Fix

Add properties on `EditorStore`:

```swift
var canSave: Bool { activeDocument != nil }
var canRevert: Bool { activeDocument?.canRevert ?? false }
var canExecute: Bool { activeDocument != nil && activeDocument?.isEvaluating != true }
var isExecuting: Bool { activeDocument?.isEvaluating ?? false }
var hasOutput: Bool { activeDocument?.hasOutput ?? false }
```

Then call sites become `.disabled(!store.canSave)`, `.disabled(!store.canRevert)`, etc.

## Related

- `EditorDocument.canRevert` and `EditorDocument.hasOutput` already exist.
