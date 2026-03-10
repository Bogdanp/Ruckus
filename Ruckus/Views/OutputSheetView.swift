import SwiftUI
import UIKit

struct OutputSheetView: View {
  let text: NSAttributedString
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      OutputTextView(text: text)
        .presentationDragIndicator(.visible)
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

  func makeUIView(context: Context) -> UIScrollView {
    let textView = UITextView()
    textView.isEditable = false
    textView.isSelectable = true
    textView.isScrollEnabled = false
    textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    textView.textContainer.widthTracksTextView = false
    textView.textContainer.lineBreakMode = .byClipping
    textView.textContainer.size.width = CGFloat.greatestFiniteMagnitude
    textView.backgroundColor = .clear
    textView.translatesAutoresizingMaskIntoConstraints = false

    let scrollView = UIScrollView()
    scrollView.addSubview(textView)
    NSLayoutConstraint.activate([
      textView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
      textView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      textView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      textView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor)
    ])

    context.coordinator.textView = textView
    return scrollView
  }

  func updateUIView(_ scrollView: UIScrollView, context: Context) {
    guard let textView = context.coordinator.textView else { return }
    textView.attributedText = text
    textView.textContainer.size.width = CGFloat.greatestFiniteMagnitude
    let size = textView.sizeThatFits(CGSize(
      width: CGFloat.greatestFiniteMagnitude,
      height: CGFloat.greatestFiniteMagnitude
    ))
    textView.frame.size = size
    scrollView.contentSize = size
  }

  func makeCoordinator() -> Coordinator { Coordinator() }

  final class Coordinator {
    weak var textView: UITextView?
  }
}
