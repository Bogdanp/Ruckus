# Block Comments Not Handled in Indenter

## Summary

`RacketIndenter.lastUnmatchedOpenParen` correctly handles line comments (`;`)
and string literals, but does not account for Racket's block comment syntax
`#|...|#`. Parentheses inside block comments are incorrectly counted as real
delimiters, causing wrong indentation for any code following a block comment
that contains parentheses.

## Affected Code

### `RacketIndenter.swift:44-80` — `lastUnmatchedOpenParen(in:)`

```swift
private func lastUnmatchedOpenParen(
    in chars: [Character]
) -> (column: Int, index: Int)? {
    var stack: [(column: Int, index: Int)] = []
    var inString = false
    var escaped = false
    var inLineComment = false
    var col = 0
    for (idx, char) in chars.enumerated() {
        // ...
        if inLineComment {
            if char.isNewline { inLineComment = false }
            continue
        }
        // ...
        switch char {
        case "\"": inString = true
        case ";": inLineComment = true
        case "(", "[", "{":
            stack.append((column: charCol, index: idx))
        case ")", "]", "}":
            if !stack.isEmpty { stack.removeLast() }
        default: break
        }
    }
    return stack.last
}
```

There is no `inBlockComment` state. The parser processes `#|...|#` as normal
characters, so any `(`, `)`, `[`, `]`, `{`, `}` inside a block comment
modifies the paren stack incorrectly.

## Reproduction Scenario

```racket
#|
This is a block comment with (unmatched parens
|#
(define x 42)
```

When pressing Enter after the `(define x 42)` line:

1. The indenter scans from the beginning.
2. It encounters `(` inside the block comment → pushes to stack.
3. The `|#` closing the block comment is treated as regular characters.
4. The `(define x 42)` paren is pushed, then `)` pops it.
5. The stack still has the spurious `(` from the comment → indentation is
   calculated relative to it, producing wrong results.

Expected indentation: column 0 (top level).
Actual indentation: indented to align with the paren inside the comment.

## Additional Cases

Nested block comments are also valid in Racket:

```racket
#| outer #| inner |# still comment |#
```

And `#;` (datum comments) skip the next S-expression, which is a separate
issue but related in spirit.

## Suggested Fix

Add `inBlockComment` tracking with nesting support:

```swift
var inBlockComment = 0  // nesting depth
var prevChar: Character = "\0"

for (idx, char) in chars.enumerated() {
    let charCol = col
    if char.isNewline { col = 0 } else { col += 1 }
    if escaped { escaped = false; prevChar = char; continue }

    if inBlockComment > 0 {
        if prevChar == "|" && char == "#" {
            inBlockComment -= 1
            prevChar = "\0"  // prevent re-matching
            continue
        }
        if prevChar == "#" && char == "|" {
            inBlockComment += 1
            prevChar = "\0"
            continue
        }
        prevChar = char
        continue
    }

    if prevChar == "#" && char == "|" {
        inBlockComment += 1
        prevChar = "\0"
        continue
    }

    // ... rest of existing logic ...
    prevChar = char
}
```

This requires a `prevChar` variable since block comment delimiters are
two-character sequences. The nesting counter handles Racket's nested block
comments correctly.

### Test Cases to Add

```swift
@Test func blockComment() {
    // Parens inside block comments should be ignored
    #expect(indent("#| ( |#\n") == "")
}

@Test func blockCommentNested() {
    #expect(indent("#| #| |# |#\n") == "")
}

@Test func blockCommentWithCode() {
    #expect(indent("#| (foo |#\n(define x\n") == "  ")
}

@Test func blockCommentMultiline() {
    #expect(indent("#|\nfoo\n(bar\n|#\n(define x\n") == "  ")
}
```

## Related

- The `isSymbolChar` function (line 82) also doesn't account for `#` as a
  potential block-comment starter, but this is less impactful since `#` by
  itself isn't a delimiter.
