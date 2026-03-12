import Runestone
import UIKit

@MainActor
final class DocumentObserver {
  weak var currentDocument: EditorDocument? {
    didSet { generation &+= 1 }
  }

  /// Incremented on every document switch so stale observation chains
  /// exit immediately instead of lingering until the old document changes.
  private var generation: UInt = 0

  func observeCode(of document: EditorDocument, in textView: TextView) {
    let expectedGeneration = generation
    nonisolated(unsafe) let document = document
    nonisolated(unsafe) weak let weakDocument = document
    withObservationTracking {
      _ = document.code
    } onChange: { [weak self, weak textView] in
      Task { @MainActor in
        guard let self, let textView,
              self.generation == expectedGeneration,
              let document = weakDocument,
              document === self.currentDocument else { return }
        if textView.text != document.code {
          textView.text = document.code
        }
        self.observeCode(of: document, in: textView)
      }
    }
  }
}
