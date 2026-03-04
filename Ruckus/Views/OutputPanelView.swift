import SwiftUI
import UIKit

struct OutputPanelView: View {
  let text: String

  var body: some View {
    Divider()
    OutputTextView(text: text)
      .frame(maxHeight: 200)
      .background(.quaternary)
  }
}

private struct OutputTextView: UIViewRepresentable {
  let text: String

  func makeUIView(context: Context) -> UITextView {
    let view = UITextView()
    view.isEditable = false
    view.isSelectable = true
    view.font = .monospacedSystemFont(ofSize: UIFont.smallSystemFontSize, weight: .regular)
    view.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    view.textContainer.lineBreakMode = .byClipping
    view.textContainer.widthTracksTextView = false
    view.textContainer.size = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    view.backgroundColor = .clear
    return view
  }

  func updateUIView(_ view: UITextView, context: Context) {
    view.text = text
  }
}
