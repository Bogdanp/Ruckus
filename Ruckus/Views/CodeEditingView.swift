import Runestone
import SwiftUI

struct CodeEditingView: UIViewRepresentable {
  @Binding var text: String
  @Binding var textViewUndoManager: UndoManager?

  func makeCoordinator() -> Coordinator {
    Coordinator(text: $text)
  }

  func makeUIView(context: Context) -> TextView {
    let textView = TextView(frame: .zero)
    textView.editorDelegate = context.coordinator
    textView.showLineNumbers = true
    textView.autocapitalizationType = .none
    textView.autocorrectionType = .no
    textView.indentStrategy = .space(length: 2)
    let state = TextViewState(text: text, theme: DefaultTheme(), language: .racket)
    textView.setState(state)
    DispatchQueue.main.async {
      textViewUndoManager = textView.undoManager
    }
    return textView
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
