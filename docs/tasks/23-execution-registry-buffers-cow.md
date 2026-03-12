# Avoid copy-on-write overhead in ExecutionRegistry.withBuffers

## Summary

`ExecutionRegistry.withBuffers(for:_:)` copies the `(OutputBuffer,
OutputBuffer)` tuple out of the dictionary, passes it to the closure by
`inout`, then writes it back. This runs on every execution step during output
streaming. If `OutputBuffer` is a struct with non-trivial storage, each call
triggers a copy-on-write of both buffers.

## Affected Code

### `Ruckus/Models/ExecutionRegistry.swift`

```swift
func withBuffers(
  for executionId: UInt64,
  _ body: (inout OutputBuffer, inout OutputBuffer) -> Void
) {
  guard var pair = outputBuffers[executionId] else { return }
  body(&pair.stdout, &pair.stderr)
  outputBuffers[executionId] = pair
}
```

## Suggested Fix

If `OutputBuffer` is a struct, consider making it a class (reference type) so
the dictionary holds a reference and mutations happen in place without the
get/mutate/set cycle. Alternatively, use a wrapper class:

```swift
final class BufferPair {
  var stdout = OutputBuffer()
  var stderr = OutputBuffer()
}
```

Then `withBuffers` can mutate through the reference without copying:

```swift
func withBuffers(for executionId: UInt64, _ body: (BufferPair) -> Void) {
  guard let pair = outputBuffers[executionId] else { return }
  body(pair)
}
```
