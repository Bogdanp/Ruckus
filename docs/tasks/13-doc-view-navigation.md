# Documentation View Navigation Controls

## Summary

The documentation view (`DocumentationView`) embeds a `WKWebView` that loads
the bundled Racket docs, but provides no browser-style navigation controls.
Once a user follows a link away from the index page, there is no way to go
back, go forward, or return home without dismissing and re-opening the view.
A location bar showing the current page title or path would also help
orientation inside the doc tree.

## Affected Code

### `Ruckus/Views/Settings/DocumentationView.swift:4-23`

```swift
struct DocumentationView: View {
  var body: some View {
    DocumentationWebView()
      .navigationTitle("Documentation")
      .navigationBarTitleDisplayMode(.inline)
      .ignoresSafeArea(edges: .bottom)
  }
}

private struct DocumentationWebView: UIViewRepresentable {
  func makeUIView(context: Context) -> WKWebView {
    let webView = WKWebView()
    if let url = Bundle.main.url(forResource: "doc/index", withExtension: "html", subdirectory: "racket") {
      webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }
    return webView
  }

  func updateUIView(_ webView: WKWebView, context: Context) {}
}
```

The `WKWebView` is created as a fire-and-forget representable with no
coordinator, no observation of navigation state, and no exposed controls.

## Impact

Users browsing the Racket documentation cannot navigate back after following
a link, making the docs frustrating to explore. The only workaround is to
close and reopen the documentation view, which always returns to the index.

## Suggested Fix

1. **Add a `Coordinator`** to `DocumentationWebView` that acts as the
   `WKNavigationDelegate` and publishes navigation state (`canGoBack`,
   `canGoForward`, current page title/URL) via an `@Observable` view model.

2. **Add a toolbar** to `DocumentationView` with:
   - **Back / Forward buttons** (`chevron.left` / `chevron.right`) that call
     `webView.goBack()` / `webView.goForward()`, disabled when the web view
     reports it cannot navigate in that direction.
   - **Home button** (`house`) that reloads the index URL.
   - **Location bar** — a non-editable text field (or a compact label) in the
     toolbar or below the navigation title showing the current page title.
     A full editable URL bar is unnecessary since the content is local.

3. **Preserve the `WKWebView` instance** across SwiftUI updates. The current
   `makeUIView`/`updateUIView` pattern already does this, but the coordinator
   should use KVO on `canGoBack`, `canGoForward`, and `title` to keep the
   toolbar state in sync.

Skeleton:

```swift
@Observable
final class DocNavigationState {
  var canGoBack = false
  var canGoForward = false
  var title: String = "Documentation"
}

// In Coordinator:
override func observeValue(forKeyPath keyPath: String?, ...) {
  state.canGoBack = webView.canGoBack
  state.canGoForward = webView.canGoForward
  state.title = webView.title ?? "Documentation"
}
```

```swift
// In DocumentationView toolbar:
ToolbarItemGroup(placement: .bottomBar) {
  Button { webView.goBack() } label: { Image(systemName: "chevron.left") }
    .disabled(!navState.canGoBack)
  Button { webView.goForward() } label: { Image(systemName: "chevron.right") }
    .disabled(!navState.canGoForward)
  Spacer()
  Text(navState.title).font(.caption).lineLimit(1)
  Spacer()
  Button { webView.load(indexURL) } label: { Image(systemName: "house") }
}
```

## Related

- None.
