# Replace Retroactive URL+Identifiable With a Wrapper Type

## Summary

`URL+Identifiable.swift` adds a retroactive `Identifiable` conformance to
`Foundation.URL`. This is a global extension — if any dependency also
conforms `URL` to `Identifiable` (or if Apple adds it in a future SDK), the
build will fail with a duplicate conformance error.

## Affected Code

### `URL+Identifiable.swift:1-5`

```swift
import Foundation

extension URL: @retroactive Identifiable {
  public var id: String { absoluteString }
}
```

### `ContentView.swift:98`

```swift
.sheet(item: $shareFileURL) { url in
  ActivitySheet(items: [url])
}
```

This is the only place where `URL` needs to be `Identifiable` — the
`.sheet(item:)` modifier requires it.

## Impact

Build breakage if a future iOS SDK or dependency adds `URL: Identifiable`.
The `@retroactive` attribute suppresses the warning but does not prevent the
conflict.

## Suggested Fix

Use a thin wrapper:

```swift
struct IdentifiableURL: Identifiable {
  let url: URL
  var id: String { url.absoluteString }
}
```

Change `shareFileURL` from `URL?` to `IdentifiableURL?` and update the
one usage site:

```swift
@State private var shareFileURL: IdentifiableURL?

.sheet(item: $shareFileURL) { item in
  ActivitySheet(items: [item.url])
}
```

Then delete `URL+Identifiable.swift`.

## Related

- None.
