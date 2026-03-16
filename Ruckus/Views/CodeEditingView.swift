import ObjectiveC
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
    disableWritingTools(on: textView)
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
    coordinator.completionController.updatePalette(settings.colorPalette)
    coordinator.currentFont = settings.font
    coordinator.currentThemeName = settings.themeName
    coordinator.highlightController.applyColors(from: settings)
    coordinator.documentObserver.observeCode(of: document, in: textView)
    coordinator.highlightController.updateBracketHighlights(in: textView)

    return textView
  }

  /// Disable Apple Writing Tools (Proofread/Rewrite) on the underlying text input view.
  /// Runestone's TextInputView conforms to UITextInputTraits but doesn't implement the
  /// optional `writingToolsBehavior` property, so UIKit defaults to `.default` (enabled).
  /// We add a getter returning `.none` (-1) via the ObjC runtime to suppress it.
  private func disableWritingTools(on textView: TextView) {
    guard let inputView = textView.subviews.first(where: { $0 is UITextInput })
    else { return }
    let sel = NSSelectorFromString("writingToolsBehavior")
    if inputView.responds(to: sel) {
      inputView.setValue(-1, forKey: "writingToolsBehavior")
    } else {
      let getter: @convention(block) (AnyObject) -> Int = { _ in -1 }
      class_addMethod(
        type(of: inputView), sel, imp_implementationWithBlock(getter), "q@:"
      )
    }
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
      coordinator.switchDocument(
        to: document, in: textView, font: font, palette: settings.colorPalette
      )
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
      coordinator.completionController.updatePalette(settings.colorPalette)
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

  @MainActor
  class Coordinator: @preconcurrency TextViewDelegate {
    let completionController = CompletionController()
    let highlightController = HighlightController()
    let documentObserver = DocumentObserver()
    var currentFont: UIFont?
    var currentThemeName: ColorThemeName?
    private var didType = false
    private let indenter = RacketIndenter()

    private static let autoPairs: [String: String] = [
      "(": ")", "[": "]", "{": "}", "\"": "\""
    ]
    private static let closers: Set<String> = Set(autoPairs.values)

    init(document: EditorDocument) {
      self.documentObserver.currentDocument = document
    }

    func switchDocument(
      to document: EditorDocument, in textView: TextView,
      font: UIFont, palette: ColorPalette?
    ) {
      if let prev = documentObserver.currentDocument {
        prev.savedContentOffset = textView.contentOffset
        prev.savedSelectedRange = textView.selectedRange
      }
      let theme = EditorTheme(font: font, palette: palette)
      let state = TextViewState(text: document.code, theme: theme, language: .racket)
      textView.editorDelegate = nil
      textView.highlightedRanges = []
      textView.selectedRange = NSRange(location: 0, length: 0)
      textView.setState(state)
      textView.editorDelegate = self
      textView.backgroundColor = theme.backgroundColor
      documentObserver.currentDocument = document
      documentObserver.observeCode(of: document, in: textView)
      completionController.dismiss()
      highlightController.clearMatchState()
      highlightController.updateBracketHighlights(in: textView)
      let savedRange = document.savedSelectedRange ?? NSRange(location: 0, length: 0)
      let textLength = (textView.text as NSString).length
      let location = min(savedRange.location, textLength)
      let length = min(savedRange.length, textLength - location)
      textView.selectedRange = NSRange(location: location, length: length)
      textView.layoutIfNeeded()
      if let offset = document.savedContentOffset {
        textView.contentOffset = offset
      }
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
      // Paired delete: backspace between matched pair removes both.
      if text.isEmpty, range.length == 1 {
        let source = textView.text
        let loc = range.location
        let nsSource = source as NSString
        if loc + 1 < nsSource.length {
          let deleted = nsSource.substring(with: NSRange(location: loc, length: 1))
          let next = nsSource.substring(with: NSRange(location: loc + 1, length: 1))
          if Self.autoPairs[deleted] == next {
            // Delete both the opener and its closer.
            let pairRange = NSRange(location: loc, length: 2)
            textView.selectedRange = pairRange
            textView.insertText("")
            return false
          }
        }
      }

      // Skip-over: typing a closer that already follows the cursor.
      if range.length == 0, Self.closers.contains(text) {
        let source = textView.text
        let nsSource = source as NSString
        if range.location < nsSource.length {
          let next = nsSource.substring(with: NSRange(location: range.location, length: 1))
          if next == text {
            textView.selectedRange = NSRange(location: range.location + 1, length: 0)
            return false
          }
        }
      }

      // Auto-pair: insert matching closer after opener.
      if range.length == 0, let closer = Self.autoPairs[text] {
        textView.insertText(text + closer)
        let cursor = range.location + text.utf16.count
        textView.selectedRange = NSRange(location: cursor, length: 0)
        return false
      }

      // Auto-indent on newline.
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
