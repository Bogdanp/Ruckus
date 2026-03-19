# Clarify canExecute logic in EditorStore

## Summary

`canExecute` uses a double-nil-check pattern that obscures the intent.

## Affected Code

### `Ruckus/Models/EditorStore.swift:31`

```swift
var canExecute: Bool { activeDocument != nil && activeDocument?.isEvaluating != true }
```

The second operand `activeDocument?.isEvaluating != true` evaluates to
`true` when `activeDocument` is nil (because `nil != true`), so the
first nil check is necessary but the intent is not obvious.

## Suggested Fix

```swift
var canExecute: Bool { activeDocument.map { !$0.isEvaluating } ?? false }
```
