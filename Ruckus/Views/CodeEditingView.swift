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
    textView.inputAccessoryView = EditorAccessoryBar.makeInputAccessoryView(
      for: textView, palette: settings.colorPalette
    )
    let theme = EditorTheme(font: settings.font, palette: settings.colorPalette)
    let state = TextViewState(text: document.code, theme: theme, language: .racket)
    textView.setState(state)
    textView.backgroundColor = theme.backgroundColor
    applyInsertionPointColor(to: textView)

    let coordinator = context.coordinator
    let popover = CompletionPopover(font: settings.font) { suffix in
      textView.insertText(suffix)
    }
    coordinator.completionController.setPopover(popover)
    coordinator.currentFont = settings.font
    coordinator.currentThemeName = settings.themeName
    coordinator.highlightController.applyColors(from: settings)
    coordinator.documentObserver.observeCode(of: document, in: textView)
    coordinator.highlightController.updateBracketHighlights(in: textView)

    return textView
  }

  private func applyInsertionPointColor(to textView: TextView) {
    let color = settings.colorPalette?.textColor ?? .label
    textView.insertionPointColor = color
    textView.selectionBarColor = color
    textView.selectionHighlightColor = color.withAlphaComponent(0.2)
  }

  static func dismantleUIView(_ textView: TextView, coordinator: Coordinator) {
    coordinator.completionController.tearDown()
  }

  func updateUIView(_ textView: TextView, context: Context) {
    let coordinator = context.coordinator
    let font = settings.font

    let themeChanged = font != coordinator.currentFont
      || settings.themeName != coordinator.currentThemeName
    let highlightSettingsChanged = themeChanged
      || settings.rainbowParentheses != coordinator.highlightController.rainbowEnabled

    if highlightSettingsChanged {
      coordinator.highlightController.applyColors(from: settings)
    }

    if document !== coordinator.documentObserver.currentDocument {
      switchDocument(in: textView, coordinator: coordinator, font: font)
    } else if themeChanged {
      let theme = EditorTheme(font: font, palette: settings.colorPalette)
      textView.theme = theme
      textView.backgroundColor = theme.backgroundColor
    }

    if themeChanged {
      applyInsertionPointColor(to: textView)
      textView.inputAccessoryView = EditorAccessoryBar.makeInputAccessoryView(
        for: textView, palette: settings.colorPalette
      )
      textView.reloadInputViews()
      coordinator.completionController.updateFont(font)
      coordinator.currentFont = font
      coordinator.currentThemeName = settings.themeName
    }

    if highlightSettingsChanged {
      coordinator.highlightController.updateBracketHighlights(in: textView)
    }

    if coordinator.completionController.allCompletions != completions {
      coordinator.completionController.allCompletions = completions
    }
    if let window = textView.window {
      coordinator.completionController.attachIfNeeded(to: window)
    }
    if textViewUndoManager !== textView.undoManager {
      textViewUndoManager = textView.undoManager
    }
    if findInteraction !== textView.findInteraction {
      findInteraction = textView.findInteraction
    }
  }

  private func switchDocument(
    in textView: TextView, coordinator: Coordinator, font: UIFont
  ) {
    if let prev = coordinator.documentObserver.currentDocument {
      prev.savedContentOffset = textView.contentOffset
      prev.savedSelectedRange = textView.selectedRange
    }
    let theme = EditorTheme(font: font, palette: settings.colorPalette)
    let state = TextViewState(text: document.code, theme: theme, language: .racket)
    textView.setState(state)
    textView.backgroundColor = theme.backgroundColor
    coordinator.documentObserver.currentDocument = document
    coordinator.documentObserver.observeCode(of: document, in: textView)
    textView.layoutIfNeeded()
    if let range = document.savedSelectedRange {
      textView.selectedRange = range
    }
    if let offset = document.savedContentOffset {
      textView.contentOffset = offset
    }
    coordinator.completionController.dismiss()
    coordinator.highlightController.updateBracketHighlights(in: textView)
  }

  @MainActor
  class Coordinator: @preconcurrency TextViewDelegate {
    let completionController = CompletionController()
    let highlightController = HighlightController()
    let documentObserver = DocumentObserver()
    var currentFont: UIFont?
    var currentThemeName: ColorThemeName?
    private var didType = false
    private let indenter = RacketIndenter()

    init(document: EditorDocument) {
      self.documentObserver.currentDocument = document
    }

    func textViewDidChange(_ textView: TextView) {
      guard let currentDocument = documentObserver.currentDocument else { return }
      let text = textView.text
      currentDocument.code = text
      currentDocument.isDirty = true
      didType = true
      highlightController.clearMatchState()
      highlightController.updateBracketHighlights(text: text, in: textView)
      completionController.updatePopover(text: text, for: textView)
    }

    func textViewDidChangeSelection(_ textView: TextView) {
      if !didType {
        completionController.dismiss()
      }
      didType = false
      highlightController.updateMatchHighlight(in: textView)
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
