# Fix coding style violations

## Summary

Several files violate the rules defined in the coding skill
(`.claude/skills/coding/SKILL.md`). Test assertions use boolean pleonasms
(`#expect(x == true)` instead of `#expect(x)`) and one Logger call uses a
hardcoded function name instead of `\(#function):`.

## Affected Code

### `RuckusTests/Views/Editor/CodeEditingViewTests.swift:63,98,114,132,155,175,195,214,265,299,303,361,366`

```swift
#expect(doc.isDirty == true)
#expect(result == false)
#expect(result == true)
#expect(coord.highlightController.rainbowEnabled == true)
#expect(popover.isHidden == false)
#expect(popover.isHidden == true)
#expect(doc.isDirty == false)
```

The coding skill says: "Simplify boolean expressions, avoid pleonasms like
`#expect(expression == true)` or `#expect(expression == false)`." These 13
assertions should use the bare expression or its negation.

### `Ruckus/Models/ExecutionService.swift:58`

```swift
Logger.backend.debug("saveWidgetCache: skipped — no relative path for execution \(executionId)")
```

The coding skill says Logger messages should be prefixed with `\(#function):`.
This call hardcodes `"saveWidgetCache:"` instead.

## Impact

Style inconsistency — no runtime effect, but violates the project's coding
conventions.

## Suggested Fix

### Test pleonasms

Replace each `#expect(expr == true)` with `#expect(expr)` and each
`#expect(expr == false)` with `#expect(!expr)`:

```swift
// Before
#expect(doc.isDirty == true)
#expect(result == false)
#expect(popover.isHidden == false)

// After
#expect(doc.isDirty)
#expect(!result)
#expect(!popover.isHidden)
```

### Logger prefix

```swift
// Before
Logger.backend.debug("saveWidgetCache: skipped — no relative path for execution \(executionId)")

// After
Logger.backend.debug("\(#function): skipped — no relative path for execution \(executionId)")
```

**Note:** The `== true` / `== false` patterns in production code
(`ContentView.swift`, `EditorStore.swift`, `EditorSettings.swift`,
`AsyncButton.swift`, `FolderBrowser.swift`) all involve optional chaining and
are *not* pleonasms — they are the idiomatic way to unwrap `Bool?` in Swift.

## Related

- None
