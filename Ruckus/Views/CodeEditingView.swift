import Runestone
import SwiftUI

struct CodeEditingView: UIViewRepresentable {
  @Binding var text: String
  @Binding var textViewUndoManager: UndoManager?

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
    textView.indentStrategy = .space(length: 2)
    textView.inputAccessoryView = makeInputAccessoryView(for: textView)
    let state = TextViewState(text: text, theme: DefaultTheme(), language: .racket)
    textView.setState(state)
    DispatchQueue.main.async {
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
    let bar = UIInputView(frame: CGRect(x: 0, y: 0, width: 0, height: 76), inputViewStyle: .keyboard)
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

  func updateUIView(_ textView: TextView, context: Context) {
    if textView.text != text {
      textView.text = text
    }
  }

  @MainActor
  class Coordinator: TextViewDelegate {
    var text: Binding<String>
    private let indenter = RacketIndenter()

    init(text: Binding<String>) {
      self.text = text
    }

    func textViewDidChange(_ textView: TextView) {
      text.wrappedValue = textView.text
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
  }
}
