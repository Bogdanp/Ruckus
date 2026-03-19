import SwiftUI
import WebKit

private let docIndexURL = Bundle.main.url(forResource: "doc/index", withExtension: "html", subdirectory: "racket")

@Observable
final class DocNavigationState {
  var canGoBack = false
  var canGoForward = false
  var title: String = "Documentation"
  weak var webView: WKWebView?

  func goBack() { webView?.goBack() }
  func goForward() { webView?.goForward() }

  func goHome() {
    guard let webView, let url = docIndexURL else { return }
    webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
  }
}

struct DocumentationView: View {
  @State private var navState = DocNavigationState()

  var body: some View {
    DocumentationWebView(navState: navState)
      .navigationTitle(navState.title)
      .navigationBarTitleDisplayMode(.inline)
      .ignoresSafeArea(edges: .bottom)
      .toolbar {
        ToolbarItemGroup(placement: .bottomBar) {
          Button { navState.goBack() } label: { Image(systemName: "chevron.left") }
            .disabled(!navState.canGoBack)
          Button { navState.goForward() } label: { Image(systemName: "chevron.right") }
            .disabled(!navState.canGoForward)
          Spacer()
          Button { navState.goHome() } label: { Image(systemName: "house") }
        }
      }
  }
}

private struct DocumentationWebView: UIViewRepresentable {
  let navState: DocNavigationState

  func makeCoordinator() -> Coordinator {
    Coordinator(navState: navState)
  }

  func makeUIView(context: Context) -> WKWebView {
    let webView = WKWebView()
    webView.navigationDelegate = context.coordinator
    navState.webView = webView
    if let url = docIndexURL {
      webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }
    return webView
  }

  func updateUIView(_ webView: WKWebView, context: Context) {}

  final class Coordinator: NSObject, WKNavigationDelegate {
    let navState: DocNavigationState

    init(navState: DocNavigationState) {
      self.navState = navState
    }

    private func updateState(from webView: WKWebView) {
      navState.canGoBack = webView.canGoBack
      navState.canGoForward = webView.canGoForward
      navState.title = webView.title ?? "Documentation"
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
      updateState(from: webView)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      updateState(from: webView)
    }
  }
}
