import Runestone
import SwiftUI

struct CodeEditingView: UIViewRepresentable {
  var document: EditorDocument
  @Binding var textViewUndoManager: UndoManager?
  @Binding var findInteraction: UIFindInteraction?
  var completions: [String] = []
  @Environment(EditorSettings.self) private var settings

  func makeCoordinator() -> Coordinator {
    Coordinator(document: document)
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
    textView.isFindInteractionEnabled = true
    textView.inputAccessoryView = makeInputAccessoryView(for: textView)
    let theme = EditorTheme(font: settings.font, palette: settings.colorPalette)
    let state = TextViewState(text: document.code, theme: theme, language: .racket)
    textView.setState(state)
    textView.backgroundColor = theme.backgroundColor
    applyInsertionPointColor(to: textView)

    let popover = CompletionPopover(font: settings.font) { suffix in
      textView.insertText(suffix)
    }
    context.coordinator.popover = popover
    context.coordinator.currentFont = settings.font
    context.coordinator.currentThemeName = settings.themeName
    context.coordinator.applyHighlightColors(from: settings)
    context.coordinator.observeCode(of: document, in: textView)
    context.coordinator.updateBracketHighlights(in: textView)

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
      config.baseForegroundColor = settings.colorPalette?.textColor ?? .label
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
      config.background.backgroundColor = settings.colorPalette?.gutterBackground ?? .systemBackground
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
    if let palette = settings.colorPalette {
      bar.backgroundColor = palette.backgroundColor
    }

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

  private func applyInsertionPointColor(to textView: TextView) {
    let color = settings.colorPalette?.textColor ?? .label
    textView.insertionPointColor = color
    textView.selectionBarColor = color
    textView.selectionHighlightColor = color.withAlphaComponent(0.2)
  }

  static func dismantleUIView(_ textView: TextView, coordinator: Coordinator) {
    coordinator.popover?.removeFromSuperview()
    coordinator.popover = nil
  }

  func updateUIView(_ textView: TextView, context: Context) {
    let coordinator = context.coordinator
    let font = settings.font

    let themeChanged = font != coordinator.currentFont
      || settings.themeName != coordinator.currentThemeName
    let highlightSettingsChanged = themeChanged
      || settings.rainbowParentheses != coordinator.rainbowEnabled

    if highlightSettingsChanged {
      coordinator.applyHighlightColors(from: settings)
    }

    if document !== coordinator.currentDocument {
      if let prev = coordinator.currentDocument {
        prev.savedContentOffset = textView.contentOffset
        prev.savedSelectedRange = textView.selectedRange
      }
      let theme = EditorTheme(font: font, palette: settings.colorPalette)
      let state = TextViewState(text: document.code, theme: theme, language: .racket)
      textView.setState(state)
      textView.backgroundColor = theme.backgroundColor
      coordinator.currentDocument = document
      coordinator.observeCode(of: document, in: textView)
      textView.layoutIfNeeded()
      if let range = document.savedSelectedRange {
        textView.selectedRange = range
      }
      if let offset = document.savedContentOffset {
        textView.contentOffset = offset
      }
      coordinator.popover?.dismiss()
      coordinator.updateBracketHighlights(in: textView)
    } else if themeChanged {
      let theme = EditorTheme(font: font, palette: settings.colorPalette)
      textView.theme = theme
      textView.backgroundColor = theme.backgroundColor
    }

    if themeChanged {
      applyInsertionPointColor(to: textView)
      textView.inputAccessoryView = makeInputAccessoryView(for: textView)
      textView.reloadInputViews()
      coordinator.currentFont = font
      coordinator.currentThemeName = settings.themeName
    }

    if highlightSettingsChanged {
      coordinator.updateBracketHighlights(in: textView)
    }

    coordinator.allCompletions = completions
    coordinator.popover?.updateFont(font)
    if let popover = coordinator.popover,
       popover.superview == nil,
       let window = textView.window {
      window.addSubview(popover)
    }
    if textViewUndoManager !== textView.undoManager {
      textViewUndoManager = textView.undoManager
    }
    if findInteraction !== textView.findInteraction {
      findInteraction = textView.findInteraction
    }
  }

  @MainActor
  class Coordinator: @preconcurrency TextViewDelegate {
    var allCompletions: [String] = []
    var popover: CompletionPopover?
    weak var currentDocument: EditorDocument?
    var currentFont: UIFont?
    var currentThemeName: ColorThemeName?
    var rainbowEnabled: Bool = false
    var rainbowColors: [UIColor] = BracketHighlighter.defaultColors
    var matchColor: UIColor = BracketHighlighter.matchColor
    private var didType = false
    private let indenter = RacketIndenter()

    private static let wordChars = CharacterSet.alphanumerics
      .union(CharacterSet(charactersIn: "-_!?*/+<>="))

    init(document: EditorDocument) {
      self.currentDocument = document
    }

    func observeCode(of document: EditorDocument, in textView: TextView) {
      nonisolated(unsafe) let document = document
      nonisolated(unsafe) weak let weakDocument = document
      withObservationTracking {
        _ = document.code
      } onChange: { [weak self, weak textView] in
        Task { @MainActor in
          guard let self, let textView,
                let document = weakDocument,
                document === self.currentDocument else { return }
          if textView.text != document.code {
            textView.text = document.code
          }
          self.observeCode(of: document, in: textView)
        }
      }
    }

    func textViewDidChange(_ textView: TextView) {
      guard let currentDocument else { return }
      currentDocument.code = textView.text
      currentDocument.isDirty = true
      didType = true
      lastMatchedPosition = nil
      updateBracketHighlights(in: textView)
      updatePopover(for: textView)
    }

    func textViewDidChangeSelection(_ textView: TextView) {
      if !didType {
        popover?.dismiss()
      }
      didType = false
      updateMatchHighlight(in: textView)
    }

    func applyHighlightColors(from settings: EditorSettings) {
      rainbowEnabled = settings.rainbowParentheses
      if let palette = settings.colorPalette {
        rainbowColors = palette.rainbowColors
        matchColor = palette.matchHighlightColor
      } else {
        rainbowColors = BracketHighlighter.defaultColors
        matchColor = BracketHighlighter.matchColor
      }
    }

    func updateBracketHighlights(in textView: TextView) {
      guard rainbowEnabled else {
        cachedRainbowRanges = []
        textView.highlightedRanges = cachedMatchRanges
        return
      }
      let text = textView.text
      let brackets = BracketHighlighter.findBrackets(in: text)
      var ranges: [HighlightedRange] = []
      for bracket in brackets {
        let colorIndex = bracket.depth % rainbowColors.count
        let range = HighlightedRange(
          range: NSRange(location: bracket.position, length: 1),
          color: rainbowColors[colorIndex],
          cornerRadius: 2
        )
        ranges.append(range)
      }
      cachedRainbowRanges = ranges
      textView.highlightedRanges = ranges + cachedMatchRanges
    }

    private var cachedRainbowRanges: [HighlightedRange] = []
    private var cachedMatchRanges: [HighlightedRange] = []
    private weak var flashView: UIView?
    private var lastMatchedPosition: Int?

    private func updateMatchHighlight(in textView: TextView) {
      guard let selectedRange = textView.selectedTextRange else {
        applyMatchRanges([], to: textView)
        return
      }
      let cursorPos = textView.offset(
        from: textView.beginningOfDocument, to: selectedRange.start
      )
      guard let match = BracketHighlighter.findMatch(in: textView.text, at: cursorPos) else {
        applyMatchRanges([], to: textView)
        return
      }

      // Determine which bracket the cursor is on, highlight the other one
      let cursorOnOpen = (cursorPos == match.open + 1) || (cursorPos == match.open)
      let otherPosition = cursorOnOpen ? match.close : match.open

      let ranges = [
        HighlightedRange(
          range: NSRange(location: otherPosition, length: 1),
          color: matchColor,
          cornerRadius: 2
        )
      ]
      applyMatchRanges(ranges, to: textView)

      // Flash animation on the other bracket (Xcode-style)
      if otherPosition != lastMatchedPosition {
        lastMatchedPosition = otherPosition
        flashMatchingBracket(at: otherPosition, in: textView)
      }
    }

    private func applyMatchRanges(_ ranges: [HighlightedRange], to textView: TextView) {
      if ranges.isEmpty { lastMatchedPosition = nil }
      cachedMatchRanges = ranges
      textView.highlightedRanges = cachedRainbowRanges + ranges
    }

    private func flashMatchingBracket(at position: Int, in textView: TextView) {
      flashView?.layer.removeAllAnimations()
      flashView?.removeFromSuperview()

      guard let start = textView.position(from: textView.beginningOfDocument, offset: position),
            let end = textView.position(from: start, offset: 1),
            let textRange = textView.textRange(from: start, to: end)
      else { return }

      let rects = textView.selectionRects(for: textRange)
      guard let firstRect = rects.first else { return }
      let charRect = firstRect.rect
      guard !charRect.isEmpty else { return }

      let flash = UIView(frame: charRect.insetBy(dx: -1, dy: -1))
      flash.backgroundColor = matchColor.withAlphaComponent(0.8)
      flash.layer.cornerRadius = 3
      flash.isUserInteractionEnabled = false
      textView.addSubview(flash)
      self.flashView = flash

      UIView.animate(withDuration: 0.3, delay: 0.5, options: .curveEaseOut) {
        flash.alpha = 0
      } completion: { [weak flash] _ in
        flash?.removeFromSuperview()
      }
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
