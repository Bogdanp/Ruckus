# Revert highlights.scm Unicode workaround after Runestone fix

## Summary

Commit `4d15f10` removed non-ASCII characters (`λ`, `∀`, `∃`) from
`vendor/tree-sitter-racket/queries/highlights.scm` to work around a bug in
Runestone where `TreeSitterQuery` passes `source.count` (Swift character count)
instead of `source.utf8.count` (byte count) to `ts_query_new`, silently
truncating query files that contain multi-byte UTF-8 characters.

The upstream fix is tracked in https://github.com/simonbs/Runestone/pull/419.
Once that PR is merged and released, the Runestone dependency should be updated
and the workaround reverted.

## Affected Code

### `Tuist/Package.swift:17`

```swift
.package(url: "https://github.com/simonbs/runestone.git", from: "0.5.0"),
```

Bump to whichever release includes the fix from PR #419.

### `vendor/tree-sitter-racket/queries/highlights.scm`

Revert commit `4d15f10` to restore the removed Unicode characters:

- `λ` in the keyword and parameter-binding `#match?` patterns (lines 33, 50)
- `new-∀/c` and `new-∃/c` in the function builtin `#match?` pattern (line 40)

## Impact

The dropped entries mean `λ`, `new-∀/c`, and `new-∃/c` are not highlighted as
keyword / function-builtin respectively. This is cosmetic — the ASCII aliases
(`lambda`, etc.) still highlight correctly.

## Suggested Fix

1. Wait for https://github.com/simonbs/Runestone/pull/419 to be merged and
   included in a tagged release.
2. Update the Runestone dependency version in `Tuist/Package.swift`.
3. Run `git revert 4d15f10` to restore the Unicode characters.
4. Verify comment highlighting still works with the restored file.

## Related

- Runestone PR: https://github.com/simonbs/Runestone/pull/419
- Workaround commit: `4d15f10`
