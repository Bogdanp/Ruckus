# Add inline evaluation

## Summary

Users should be able to select an expression in the editor and see its result
displayed inline, next to or below the expression. This is similar to
DrRacket's "Check Syntax" annotations and inline result display.

## Affected Code

### `Ruckus/Views/CodeEditingView.swift`

The editor has no mechanism for displaying inline annotations or overlays
alongside code.

### `Ruckus/Models/EditorStore.swift:100-136`

Execution is whole-file only. There is no way to evaluate a sub-expression.

## Impact

Users must run the entire script and mentally map output lines back to the
expressions that produced them. Inline evaluation would dramatically speed up
exploratory programming.

## Suggested Fix

1. **Depends on task 07 (interactive REPL)** — reuse the `evalExpression` RPC
   to evaluate selected text.
2. **Inline result display** — after evaluation, show the result as a
   ghost-text annotation on the same line or the line below the selection,
   styled with a muted color to distinguish it from actual code.
3. **Trigger** — add a context menu item "Evaluate Selection" as the primary
   trigger (works on all devices). Additionally, support Cmd+Shift+E as a
   keyboard shortcut for hardware keyboard users on iPad.
4. **Dismiss** — results should dismiss on the next edit or via Escape.

## Related

- Task 07: Interactive REPL (provides the evaluation backend)
