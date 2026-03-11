import Runestone
import SwiftUI

struct ThemePreviewView: UIViewRepresentable {
  var font: UIFont
  var palette: ColorPalette?

  private static let sampleCode = """
    #lang racket

    ;; Fibonacci sequence
    (define (fib n)
      (cond
        [(= n 0) 0]
        [(= n 1) 1]
        [else (+ (fib (- n 1))
                 (fib (- n 2)))]))

    (map fib '(0 1 2 3 4 5 6 7))
    """

  func makeUIView(context: Context) -> TextView {
    let textView = TextView(frame: .zero)
    textView.showLineNumbers = true
    textView.isEditable = false
    textView.isSelectable = false
    textView.textContainerInset = UIEdgeInsets(top: 8, left: 5, bottom: 8, right: 5)
    textView.gutterLeadingPadding = 8
    textView.gutterTrailingPadding = 5
    textView.isScrollEnabled = true
    let theme = EditorTheme(font: font, palette: palette)
    let state = TextViewState(text: Self.sampleCode, theme: theme, language: .racket)
    textView.setState(state)
    textView.backgroundColor = theme.backgroundColor
    return textView
  }

  func updateUIView(_ textView: TextView, context: Context) {
    let theme = EditorTheme(font: font, palette: palette)
    textView.theme = theme
    textView.backgroundColor = theme.backgroundColor
  }
}
