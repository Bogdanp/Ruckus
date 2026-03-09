import Runestone
import SwiftUI

struct CodeEditingView: UIViewRepresentable {
  @Binding var text: String
  @Binding var textViewUndoManager: UndoManager?
  var completions: [String] = []

  func makeCoordinator() -> Coordinator {
    Coordinator(text: $text)
  }

  private static let symbols: [(label: String, text: String)] = [
    ("-", "-"),
    ("(", "("), (")", ")"),
    ("[", "["), ("]", "]"),
    ("{", "{"), ("}", "}"),
    ("0", "0"), ("1", "1"), ("2", "2"), ("3", "3"), ("4", "4"),
    ("5", "5"), ("6", "6"), ("7", "7"), ("8", "8"), ("9", "9")
  ]

  private static let keywords: [(label: String, text: String)] = [
    ("#lang", "#lang "),
    ("define", "define "), ("let", "let "),
    ("if", "if "), ("cond", "cond "),
    ("case", "case "), ("match", "match "),
    ("lambda", "lambda "), ("λ", "λ ")
  ]

  func makeUIView(context: Context) -> TextView {
    let textView = TextView(frame: .zero)
    textView.editorDelegate = context.coordinator
    textView.showLineNumbers = true
    textView.autocapitalizationType = .none
    textView.autocorrectionType = .no
    textView.smartQuotesType = .no
    textView.smartDashesType = .no
    textView.indentStrategy = .space(length: 2)
    textView.textContainerInset = UIEdgeInsets(top: 8, left: 5, bottom: 8, right: 5)
    textView.gutterLeadingPadding = 8
    textView.gutterTrailingPadding = 5
    textView.inputAccessoryView = makeInputAccessoryView(for: textView)
    let state = TextViewState(text: text, theme: DefaultTheme(), language: .racket)
    textView.setState(state)

    let popover = CompletionPopover { suffix in
      textView.insertText(suffix)
    }
    context.coordinator.popover = popover

    DispatchQueue.main.async {
      textView.window?.addSubview(popover)
      textViewUndoManager = textView.undoManager
    }
    return textView
  }

  private func makeSnippetRow(
    snippets: [(label: String, text: String)],
    for textView: TextView
  ) -> UIScrollView {
    let scrollView = UIScrollView()
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.clipsToBounds = false
    scrollView.translatesAutoresizingMaskIntoConstraints = false

    let stack = UIStackView()
    stack.axis = .horizontal
    stack.spacing = 6
    stack.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(stack)

    for snippet in snippets {
      let isKeyword = snippet.label.count > 1
      var config = UIButton.Configuration.plain()
      config.title = snippet.label
      config.baseForegroundColor = .label
      config.titleTextAttributesTransformer = .init { attrs in
        var attrs = attrs
        attrs.font = .monospacedSystemFont(ofSize: isKeyword ? 15 : 17, weight: .medium)
        return attrs
      }
      config.contentInsets = NSDirectionalEdgeInsets(
        top: 6, leading: isKeyword ? 10 : 12,
        bottom: 6, trailing: isKeyword ? 10 : 12
      )
      config.background.cornerRadius = 6
      config.background.backgroundColor = .systemBackground
      let button = UIButton(configuration: config)
      button.layer.shadowColor = UIColor.black.cgColor
      button.layer.shadowOpacity = 0.15
      button.layer.shadowOffset = CGSize(width: 0, height: 1)
      button.layer.shadowRadius = 0.5
      let text = snippet.text
      button.addAction(UIAction { _ in textView.insertText(text) }, for: .touchUpInside)
      stack.addArrangedSubview(button)
    }

    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
      stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
      stack.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
    ])

    return scrollView
  }

  private func makeInputAccessoryView(for textView: TextView) -> UIInputView {
    let bar = UIInputView(
      frame: CGRect(x: 0, y: 0, width: 0, height: 76),
      inputViewStyle: .keyboard
    )
    bar.allowsSelfSizing = true

    let symbolsRow = makeSnippetRow(snippets: Self.symbols, for: textView)
    let keywordsRow = makeSnippetRow(snippets: Self.keywords, for: textView)

    let outerStack = UIStackView(arrangedSubviews: [symbolsRow, keywordsRow])
    outerStack.axis = .vertical
    outerStack.spacing = 4
    outerStack.translatesAutoresizingMaskIntoConstraints = false
    bar.addSubview(outerStack)

    NSLayoutConstraint.activate([
      outerStack.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 4),
      outerStack.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -4),
      outerStack.topAnchor.constraint(equalTo: bar.topAnchor, constant: 4),
      outerStack.bottomAnchor.constraint(equalTo: bar.bottomAnchor, constant: -4)
    ])

    return bar
  }

  static func dismantleUIView(_ textView: TextView, coordinator: Coordinator) {
    coordinator.popover?.removeFromSuperview()
    coordinator.popover = nil
  }

  func updateUIView(_ textView: TextView, context: Context) {
    if textView.text != text {
      textView.text = text
    }
    context.coordinator.allCompletions = completions
  }

  @MainActor
  class Coordinator: @preconcurrency TextViewDelegate {
    var text: Binding<String>
    var allCompletions: [String] = []
    var popover: CompletionPopover?
    private var didType = false
    private let indenter = RacketIndenter()

    private static let wordChars = CharacterSet.alphanumerics
      .union(CharacterSet(charactersIn: "-_!?*/+<>="))

    init(text: Binding<String>) {
      self.text = text
    }

    func textViewDidChange(_ textView: TextView) {
      text.wrappedValue = textView.text
      didType = true
      updatePopover(for: textView)
    }

    func textViewDidChangeSelection(_ textView: TextView) {
      if !didType {
        popover?.dismiss()
      }
      didType = false
    }

    func textView(
      _ textView: TextView,
      shouldChangeTextIn range: NSRange,
      replacementText text: String
    ) -> Bool {
      guard text == "\n" || text == "\r\n" || text == "\r" else {
        return true
      }
      let source = textView.text
      let indent = indenter.indentForNewline(in: source, at: range.location)
      guard !indent.isEmpty else { return true }
      textView.insertText("\n" + indent)
      return false
    }

    private func updatePopover(for textView: TextView) {
      guard let popover else { return }
      let prefix = currentWordPrefix(in: textView)
      let filtered: [String]
      if prefix.isEmpty {
        filtered = []
      } else {
        filtered = allCompletions.filter {
          $0.hasPrefix(prefix) && $0 != prefix
        }
      }
      guard !filtered.isEmpty else {
        popover.dismiss()
        return
      }
      popover.update(items: Array(filtered.prefix(20)), prefix: prefix)
      positionPopover(popover, in: textView)
    }

    private func positionPopover(
      _ popover: CompletionPopover, in textView: TextView
    ) {
      guard let selectedRange = textView.selectedTextRange,
            let window = textView.window
      else { return }
      let caretRect = textView.caretRect(for: selectedRange.start)
      let caretInWindow = textView.convert(caretRect, to: window)
      let originX = caretInWindow.maxX + 2
      let originY = caretInWindow.minY
      let availableWidth = window.bounds.width - originX
      popover.frame.origin = CGPoint(x: originX, y: max(4, originY))
      popover.frame.size.width = min(popover.frame.width, max(0, availableWidth))
    }

    private func currentWordPrefix(in textView: TextView) -> String {
      let text = textView.text
      guard let selectedRange = textView.selectedTextRange else { return "" }
      let cursorPos = textView.offset(
        from: textView.beginningOfDocument, to: selectedRange.start
      )
      guard cursorPos >= 0 else { return "" }
      let idx = text.index(
        text.startIndex, offsetBy: min(cursorPos, text.count)
      )
      var start = idx
      while start > text.startIndex {
        let prev = text.index(before: start)
        guard let scalar = text[prev].unicodeScalars.first,
              Self.wordChars.contains(scalar) else { break }
        start = prev
      }
      let prefix = String(text[start..<idx])
      return prefix.count >= 2 ? prefix : ""
    }
  }
}
