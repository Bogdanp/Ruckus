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

  func observeCode(of document: EditorDocument, in textView: TextView) {
    let expectedGeneration = generation
    nonisolated(unsafe) let document = document
    nonisolated(unsafe) weak var weakDocument = document
    withObservationTracking {
      _ = document.code
    } onChange: { [weak self, weak textView] in
      Task { @MainActor in
        guard let self, let textView,
              self.generation == expectedGeneration,
              let document = weakDocument,
              document === self.currentDocument else { return }
        if textView.text != document.code {
          self.onCodeChanged?(textView, document.code)
        }
        self.observeCode(of: document, in: textView)
      }
    }
  }
}
