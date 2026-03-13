import SwiftUI
import UIKit

struct OutputSheetView: View {
  let text: NSAttributedString
  @State private var showShareSheet = false

  var body: some View {
    SheetNavigation(title: "Output") {
      OutputTextView(text: text)
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            Button {
              showShareSheet = true
            } label: {
              Image(systemName: "square.and.arrow.up")
            }
          }
        }
        .sheet(isPresented: $showShareSheet) {
          ActivitySheet(items: [text.string])
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
    scrollView.delegate = context.coordinator
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

    if context.coordinator.isAnchoredToBottom(scrollView) {
      let bottomOffset = max(0, scrollView.contentSize.height - scrollView.bounds.height
        + scrollView.adjustedContentInset.bottom)
      scrollView.contentOffset.y = bottomOffset
    }
  }

  func makeCoordinator() -> Coordinator { Coordinator() }

  final class Coordinator: NSObject, UIScrollViewDelegate {
    weak var textView: UITextView?
    private var userHasScrolled = false

    func isAnchoredToBottom(_ scrollView: UIScrollView) -> Bool {
      if !userHasScrolled { return true }
      let bottomEdge = scrollView.contentSize.height - scrollView.bounds.height
        + scrollView.adjustedContentInset.bottom
      let threshold: CGFloat = 40
      return scrollView.contentOffset.y >= bottomEdge - threshold
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
      userHasScrolled = true
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
      resetAnchorIfAtBottom(scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
      if !decelerate { resetAnchorIfAtBottom(scrollView) }
    }

    private func resetAnchorIfAtBottom(_ scrollView: UIScrollView) {
      let bottomEdge = scrollView.contentSize.height - scrollView.bounds.height
        + scrollView.adjustedContentInset.bottom
      if scrollView.contentOffset.y >= bottomEdge - 40 {
        userHasScrolled = false
      }
    }
  }
}
