import Runestone
import UIKit

@MainActor
final class DocumentObserver {
  weak var currentDocument: EditorDocument? {
    didSet { generation &+= 1 }
  }

  /// Called when the document's code changes externally (e.g. formatting).
  /// The closure is responsible for applying the new text to the text view
  /// and refreshing any decorations.
  var onCodeChanged: ((TextView, String) -> Void)?

  /// Incremented on every document switch so stale observation chains
  /// exit immediately instead of lingering until the old document changes.
  private var generation: UInt = 0

  /// The text view being kept in sync with `currentDocument`. Held here rather
  /// than captured by the observation closure so the `@Sendable` `onChange`
  /// callback only captures `self`, which is main-actor isolated.
  private weak var textView: TextView?

  func observeCode(of document: EditorDocument, in textView: TextView) {
    let expectedGeneration = generation
    self.textView = textView
    withObservationTracking {
      _ = document.code
    } onChange: { [weak self] in
      Task { @MainActor in
        guard let self,
              self.generation == expectedGeneration,
              let textView = self.textView,
              let document = self.currentDocument else { return }
        if textView.text != document.code {
          self.onCodeChanged?(textView, document.code)
        }
        self.observeCode(of: document, in: textView)
      }
    }
  }
}
