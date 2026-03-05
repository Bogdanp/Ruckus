# UTF-8 Assumption in Output Decoding

## Summary

Execution output from the Racket backend is decoded using
`String(data:encoding: .utf8)`. If the output contains bytes that aren't valid
UTF-8, this initializer returns `nil` and the output is silently dropped. The
user sees no output and no error for that chunk.

## Affected Code

### `AppDelegate.swift:52-57`

```swift
if let text = String(data: output.stdout, encoding: .utf8), !text.isEmpty {
    doc.appendOutput(text, stream: .stdout)
}
if let text = String(data: output.stderr, encoding: .utf8), !text.isEmpty {
    doc.appendOutput(text, stream: .stderr)
}
```

The `if let` silently handles the `nil` case (invalid UTF-8) by skipping the
output entirely.

## When This Happens

1. **Binary output**: A Racket script that writes raw bytes to stdout:
   ```racket
   (write-bytes (bytes 255 254 0 1))
   ```
   Produces bytes that aren't valid UTF-8. The entire chunk is dropped.

2. **Latin-1 or other encodings**: Racket's default output port uses UTF-8,
   but if user code changes the encoding or writes bytes directly, the output
   may not be UTF-8.

3. **Partial UTF-8 sequences**: Output is streamed in chunks. A multi-byte
   UTF-8 character (e.g. an emoji or CJK character) could be split across two
   chunks. The first chunk ends with an incomplete sequence — `String(data:
   encoding: .utf8)` returns `nil` for the entire chunk, not just the
   incomplete character.

   For example, the character "é" is `0xC3 0xA9` in UTF-8. If the first
   chunk ends at `0xC3`, that entire chunk decodes as `nil`.

## Impact

- **Scenario 3 is the most likely to hit in normal use.** Any Racket script
  that prints non-ASCII text (Unicode identifiers, string literals with
  accented characters, CJK text) may lose output lines unpredictably, depending
  on where chunk boundaries fall.
- The user sees partial or no output with no indication that data was lost.
- This is particularly confusing because it's intermittent — it depends on
  buffer timing.

## Suggested Fix

### For scenarios 1 and 2: Lossy decoding

Replace `String(data:encoding:)` with lossy decoding that replaces invalid
bytes with the Unicode replacement character:

```swift
extension String {
    init(lossyUTF8 data: Data) {
        self = String(decoding: data, as: UTF8.self)
    }
}
```

`String(decoding:as:)` with `UTF8.self` performs **lossy** decoding — invalid
sequences are replaced with U+FFFD (the replacement character) instead of
returning nil. This is the standard approach for displaying untrusted text.

Usage:

```swift
let text = String(decoding: output.stdout, as: UTF8.self)
if !text.isEmpty {
    doc.appendOutput(text, stream: .stdout)
}
```

### For scenario 3: Buffer incomplete sequences

Maintain a per-document byte buffer that accumulates output. When decoding,
check if the buffer ends with an incomplete UTF-8 sequence and hold those
trailing bytes for the next chunk:

```swift
class OutputBuffer {
    private var pending = Data()

    func append(_ data: Data) -> String {
        pending.append(data)
        // Find the last valid UTF-8 boundary
        let (decoded, remainder) = decodeToBoundary(pending)
        pending = remainder
        return decoded
    }

    private func decodeToBoundary(_ data: Data) -> (String, Data) {
        // Try decoding the whole thing
        if let str = String(data: data, encoding: .utf8) {
            return (str, Data())
        }
        // Walk backwards to find incomplete trailing sequence
        var end = data.count
        while end > 0 && end > data.count - 4 {
            end -= 1
            let prefix = data[data.startIndex..<data.index(data.startIndex, offsetBy: end)]
            if let str = String(data: prefix, encoding: .utf8) {
                let remainder = data[data.index(data.startIndex, offsetBy: end)...]
                return (str, Data(remainder))
            }
        }
        // Nothing decodes — hold everything
        return ("", data)
    }
}
```

The simpler lossy approach is probably sufficient for an IDE — binary output is
an edge case and showing replacement characters is better than dropping content.
The buffered approach is only needed if the split-sequence scenario actually
manifests in practice.
