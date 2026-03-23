# Test ExecutionService output filtering

## Summary

`ExecutionService` is at 91.9% coverage. The uncovered lines are
primarily in the `runExecution` method's step-decoding loop, which
filters out empty stdout/stderr strings before appending to the
document. This filtering logic is important — without it, empty lines
would pollute output.

## Affected Code

### `Models/ExecutionService.swift`

The step loop checks `!text.isEmpty` before calling
`doc.appendOutput(text, stream:)`. The empty-string filtering and the
error/completion branches are the uncovered paths.

## Impact

If the empty-string filter is removed, the output view would accumulate
empty attributed string segments, wasting memory and potentially
causing layout issues.

## Suggested Fix

Add a test that executes a script producing a mix of stdout, stderr, and
empty output steps. Verify that:

1. Non-empty stdout text appears in the document output.
2. Non-empty stderr text appears in the document output.
3. The document output does not contain runs from empty strings.
4. The execution completes with `.completed` result.

This requires a running Backend (like the existing `executeRunsScript`
test). A minimal script like `(display "")` followed by
`(displayln "hello")` would exercise the empty-string path.

## Related

- None
