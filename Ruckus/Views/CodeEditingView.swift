import Runestone
import SwiftUI

struct CodeEditingView: UIViewRepresentable {
  @Binding var text: String
  @Binding var textViewUndoManager: UndoManager?

  func makeCoordinator() -> Coordinator {
    Coordinator(text: $text)
  }

  private static let snippets: [(label: String, text: String)] = [
    ("(", "("), (")", ")"),
    ("[", "["), ("]", "]"),
    ("{", "{"), ("}", "}"),
    ("#lang", "#lang "),
    ("define", "define "), ("let", "let "),
    ("if", "if "), ("cond", "cond "),
    ("case", "case "), ("match", "match "),
    ("lambda", "lambda "), ("λ", "λ "),
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

  private func makeInputAccessoryView(for textView: TextView) -> UIInputView {
    let bar = UIInputView(frame: CGRect(x: 0, y: 0, width: 0, height: 40), inputViewStyle: .keyboard)
    bar.allowsSelfSizing = true

    let scrollView = UIScrollView()
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.clipsToBounds = false
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    bar.addSubview(scrollView)

    let stack = UIStackView()
    stack.axis = .horizontal
    stack.spacing = 6
    stack.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(stack)

    for snippet in Self.snippets {
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
      scrollView.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 4),
      scrollView.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -4),
      scrollView.topAnchor.constraint(equalTo: bar.topAnchor, constant: 4),
      scrollView.bottomAnchor.constraint(equalTo: bar.bottomAnchor, constant: -4),
      stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
      stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
      stack.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
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
      let indent = Self.indentForNewline(in: source, at: range.location)
      guard !indent.isEmpty else { return true }
      textView.insertText("\n" + indent)
      return false
    }

    static func indentForNewline(in text: String, at offset: Int) -> String {
      String(repeating: "  ", count: parenDepth(in: text, upTo: offset))
    }

    // swiftlint:disable:next cyclomatic_complexity
    private static func parenDepth(in text: String, upTo offset: Int) -> Int {
      var depth = 0
      var inString = false
      var escaped = false
      var inLineComment = false
      for char in text.prefix(offset) {
        if escaped { escaped = false; continue }
        if inLineComment {
          if char.isNewline { inLineComment = false }
          continue
        }
        if inString {
          switch char {
          case "\\": escaped = true
          case "\"": inString = false
          default: break
          }
          continue
        }
        switch char {
        case "\"": inString = true
        case ";": inLineComment = true
        case "(", "[", "{": depth += 1
        case ")", "]", "}": depth = max(depth - 1, 0)
        default: break
        }
      }
      return depth
    }
  }
}
