import SwiftUI
import WebKit

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
