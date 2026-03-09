import SwiftUI
import UIKit

struct OutputSheetView: View {
  let text: NSAttributedString
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      OutputTextView(text: text)
        .navigationTitle("Output")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .confirmationAction) {
            Button("Done") { dismiss() }
          }
        }
    }
  }
}

private struct OutputTextView: UIViewRepresentable {
  let text: NSAttributedString

  func makeUIView(context: Context) -> UITextView {
    let view = UITextView()
    view.isEditable = false
    view.isSelectable = true
    view.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    view.textContainer.lineBreakMode = .byClipping
    view.textContainer.widthTracksTextView = false
    view.textContainer.size = CGSize(
      width: CGFloat.greatestFiniteMagnitude,
      height: CGFloat.greatestFiniteMagnitude
    )
    view.backgroundColor = .clear
    return view
  }

  func updateUIView(_ view: UITextView, context: Context) {
    view.attributedText = text
  }
}
