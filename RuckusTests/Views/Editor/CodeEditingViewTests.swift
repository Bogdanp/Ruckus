import Runestone
import Testing
import UIKit

@testable import Ruckus

@Suite
@MainActor
struct CodeEditingViewTests {

  // MARK: - Helpers

  /// Creates a TextView initialized with plain-text state (no tree-sitter
  /// highlights needed) and places it inside a window so that UIKit geometry
  /// APIs like `selectedTextRange` return usable values.
  private func makeTextView(
    text: String,
    frame: CGRect = CGRect(x: 0, y: 0, width: 375, height: 667)
  ) -> TextView {
    let view = TextView(frame: frame)
    let theme = EditorTheme(font: .monospacedSystemFont(ofSize: 14, weight: .regular))
    let state = TextViewState(text: text, theme: theme)
    view.setState(state)

    // Put in a window so UITextInput geometry works.
    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
      return view
    }
    let window = UIWindow(windowScene: scene)
    window.addSubview(view)
    view.frame = frame
    view.layoutIfNeeded()
    return view
  }

  private func makeCoordinator(
    document: EditorDocument
  ) -> CodeEditingView.Coordinator {
    CodeEditingView.Coordinator(document: document)
  }

  private func rainbowSettings() -> EditorSettings {
    let settings = EditorSettings()
    settings.rainbowParentheses = true
    settings.themeName = .dracula
    return settings
  }

  // MARK: - textViewDidChange

  @Test
  func textViewDidChangeUpdatesDocumentCode() {
    let doc = EditorDocument(code: "hello")
    let coord = makeCoordinator(document: doc)
    let textView = makeTextView(text: "hello")
    coord.documentObserver.currentDocument = doc

    // Simulate a user edit: replace text and call delegate.
    textView.text = "hello world"
    coord.textViewDidChange(textView)

    #expect(doc.code == "hello world")
    #expect(doc.isDirty)
  }

  @Test
  func textViewDidChangeUpdatesBracketHighlights() {
    let doc = EditorDocument(code: "()")
    let coord = makeCoordinator(document: doc)
    let textView = makeTextView(text: "()")
    coord.documentObserver.currentDocument = doc
    coord.highlightController.applyColors(from: rainbowSettings())

    textView.text = "(())"
    coord.textViewDidChange(textView)

    #expect(textView.highlightedRanges.count > 0)
  }

  // MARK: - shouldChangeTextIn (newline indentation)

  @Test
  func shouldChangeTextInInsertsIndentedNewline() {
    let source = "(define (foo)\n  bar"
    let doc = EditorDocument(code: source)
    let coord = makeCoordinator(document: doc)
    let textView = makeTextView(text: source)
    coord.documentObserver.currentDocument = doc

    // The cursor is at the end of the text.
    let result = coord.textView(
      textView,
      shouldChangeTextIn: NSRange(location: source.count, length: 0),
      replacementText: "\n"
    )

    // Returns false when it handles the insertion itself.
    #expect(!result)
  }

  @Test
  func shouldChangeTextInAllowsNonNewlineText() {
    let doc = EditorDocument(code: "")
    let coord = makeCoordinator(document: doc)
    let textView = makeTextView(text: "")
    coord.documentObserver.currentDocument = doc

    let result = coord.textView(
      textView,
      shouldChangeTextIn: NSRange(location: 0, length: 0),
      replacementText: "a"
    )

    #expect(result)
  }

  @Test
  func shouldChangeTextInAllowsNewlineAtTopLevel() {
    let doc = EditorDocument(code: "hello")
    let coord = makeCoordinator(document: doc)
    let textView = makeTextView(text: "hello")
    coord.documentObserver.currentDocument = doc

    // At top-level, no indentation needed, so the indenter returns ""
    // and shouldChangeTextIn returns true (lets the system handle it).
    let result = coord.textView(
      textView,
      shouldChangeTextIn: NSRange(location: 5, length: 0),
      replacementText: "\n"
    )

    #expect(result)
  }

  // MARK: - Auto-pair brackets

  @Test(arguments: [
    ("(", "()"),
    ("[", "[]"),
    ("{", "{}"),
    ("\"", "\"\"")
  ])
  func autoPairInsertsCloser(opener: String, expected: String) {
    let doc = EditorDocument(code: "")
    let coord = makeCoordinator(document: doc)
    let textView = makeTextView(text: "")
    coord.documentObserver.currentDocument = doc

    let result = coord.textView(
      textView,
      shouldChangeTextIn: NSRange(location: 0, length: 0),
      replacementText: opener
    )

    #expect(!result)
    #expect(textView.text == expected)
    #expect(textView.selectedRange == NSRange(location: 1, length: 0))
  }

  @Test
  func skipOverClosingParen() {
    let source = "()"
    let doc = EditorDocument(code: source)
    let coord = makeCoordinator(document: doc)
    let textView = makeTextView(text: source)
    coord.documentObserver.currentDocument = doc

    // Cursor between parens, typing ')' should skip over.
    let result = coord.textView(
      textView,
      shouldChangeTextIn: NSRange(location: 1, length: 0),
      replacementText: ")"
    )

    #expect(!result)
    #expect(textView.text == "()")
    #expect(textView.selectedRange == NSRange(location: 2, length: 0))
  }

  @Test
  func pairedDeleteRemovesBothBrackets() {
    let source = "()"
    let doc = EditorDocument(code: source)
    let coord = makeCoordinator(document: doc)
    let textView = makeTextView(text: source)
    coord.documentObserver.currentDocument = doc

    // Simulate backspace deleting '(' when cursor is between the pair.
    let result = coord.textView(
      textView,
      shouldChangeTextIn: NSRange(location: 0, length: 1),
      replacementText: ""
    )

    #expect(!result)
    #expect(textView.text == "")
  }

  @Test
  func backspaceWithoutPairPassesThrough() {
    let source = "(a)"
    let doc = EditorDocument(code: source)
    let coord = makeCoordinator(document: doc)
    let textView = makeTextView(text: source)
    coord.documentObserver.currentDocument = doc

    // Deleting '(' when next char is 'a', not the closer — should pass through.
    let result = coord.textView(
      textView,
      shouldChangeTextIn: NSRange(location: 0, length: 1),
      replacementText: ""
    )

    #expect(result)
  }

  // MARK: - Rainbow bracket highlights

  @Test
  func updateBracketHighlightsAddsRangesWhenEnabled() {
    let code = "(define (foo) bar)"
    let doc = EditorDocument(code: code)
    let coord = makeCoordinator(document: doc)
    let textView = makeTextView(text: code)
    coord.highlightController.applyColors(from: rainbowSettings())

    coord.highlightController.updateBracketHighlights(in: textView)

    // 4 brackets: ( ( ) )
    #expect(textView.highlightedRanges.count == 4)
  }

  @Test
  func updateBracketHighlightsClearsRangesWhenDisabled() {
    let code = "(define (foo) bar)"
    let doc = EditorDocument(code: code)
    let coord = makeCoordinator(document: doc)
    let textView = makeTextView(text: code)

    // First enable and populate.
    coord.highlightController.applyColors(from: rainbowSettings())
    coord.highlightController.updateBracketHighlights(in: textView)
    #expect(textView.highlightedRanges.count > 0)

    // Now disable.
    let disabledSettings = EditorSettings()
    disabledSettings.rainbowParentheses = false
    coord.highlightController.applyColors(from: disabledSettings)
    coord.highlightController.updateBracketHighlights(in: textView)
    #expect(textView.highlightedRanges.count == 0)
  }

  // MARK: - applyHighlightColors

  @Test
  func applyHighlightColorsReadsSettings() {
    let doc = EditorDocument()
    let coord = makeCoordinator(document: doc)
    let settings = EditorSettings()
    settings.rainbowParentheses = true
    settings.themeName = .dracula

    coord.highlightController.applyColors(from: settings)

    #expect(coord.highlightController.rainbowEnabled)
    if let palette = ColorThemeName.dracula.palette {
      #expect(coord.highlightController.rainbowColors == palette.rainbowColors)
      #expect(coord.highlightController.matchColor == palette.matchHighlightColor)
    }
  }

  @Test
  func applyHighlightColorsUsesDefaultsForSystemTheme() {
    let doc = EditorDocument()
    let coord = makeCoordinator(document: doc)
    let settings = EditorSettings()
    settings.themeName = .system

    coord.highlightController.applyColors(from: settings)

    #expect(coord.highlightController.rainbowColors == BracketHighlighter.defaultColors)
    #expect(coord.highlightController.matchColor == BracketHighlighter.matchColor)
  }

  // MARK: - Completion popover

  @Test
  func popoverDismissedOnSelectionChangeWithoutTyping() {
    let doc = EditorDocument(code: "define")
    let coord = makeCoordinator(document: doc)
    let textView = makeTextView(text: "define")
    coord.documentObserver.currentDocument = doc

    let popover = CompletionPopover { _ in }
    coord.completionController.setPopover(popover)

    // Show the popover with some items.
    popover.update(items: ["define-values", "define-syntax"], prefix: "define")
    #expect(!popover.isHidden)

    // Selection change without typing should dismiss.
    coord.textViewDidChangeSelection(textView)
    #expect(popover.isHidden)
  }

  // MARK: - Document observation

  @Test
  func observeCodeSyncsExternalChanges() async {
    let doc = EditorDocument(code: "initial")
    let coord = makeCoordinator(document: doc)
    let textView = makeTextView(text: "initial")
    coord.documentObserver.currentDocument = doc

    coord.documentObserver.observeCode(of: doc, in: textView)

    // External change to document.
    doc.code = "updated externally"

    // The observation fires asynchronously via Task { @MainActor }.
    // Yield several times to let the observation dispatch.
    for _ in 0..<10 {
      await Task.yield()
    }

    #expect(textView.text == "updated externally")
  }

  @Test
  func observeCodeIgnoresStaleDocument() async {
    let doc1 = EditorDocument(code: "doc1")
    let doc2 = EditorDocument(code: "doc2")
    let coord = makeCoordinator(document: doc1)
    let textView = makeTextView(text: "doc1")

    coord.documentObserver.observeCode(of: doc1, in: textView)

    // Switch to a different document.
    coord.documentObserver.currentDocument = doc2

    // Change the old document.
    doc1.code = "doc1 changed"

    for _ in 0..<10 {
      await Task.yield()
    }

    // Text view should NOT have updated because currentDocument changed.
    #expect(textView.text == "doc1")
  }

  // MARK: - Document switching

  @Test
  func textViewDidChangeTracksDirtyFlag() {
    let doc = EditorDocument(code: "clean")
    let coord = makeCoordinator(document: doc)
    let textView = makeTextView(text: "clean")
    coord.documentObserver.currentDocument = doc

    #expect(!doc.isDirty)

    textView.text = "dirty"
    coord.textViewDidChange(textView)

    #expect(doc.isDirty)
  }

  @Test
  func multipleEditsAccumulate() {
    let doc = EditorDocument(code: "a")
    let coord = makeCoordinator(document: doc)
    let textView = makeTextView(text: "a")
    coord.documentObserver.currentDocument = doc

    textView.text = "ab"
    coord.textViewDidChange(textView)
    #expect(doc.code == "ab")

    textView.text = "abc"
    coord.textViewDidChange(textView)
    #expect(doc.code == "abc")
  }

  // MARK: - Edge cases

  @Test
  func textViewDidChangeWithNilDocumentIsNoOp() {
    let doc = EditorDocument(code: "test")
    let coord = makeCoordinator(document: doc)
    let textView = makeTextView(text: "test")

    // Clear the document reference.
    coord.documentObserver.currentDocument = nil

    textView.text = "changed"
    // Should not crash.
    coord.textViewDidChange(textView)

    // Original doc should be unchanged.
    #expect(doc.code == "test")
  }

  @Test
  func bracketHighlightsWithEmptyText() {
    let doc = EditorDocument(code: "")
    let coord = makeCoordinator(document: doc)
    let textView = makeTextView(text: "")
    coord.highlightController.applyColors(from: rainbowSettings())

    coord.highlightController.updateBracketHighlights(in: textView)

    #expect(textView.highlightedRanges.count == 0)
  }

  @Test
  func bracketHighlightsWithUnmatchedParens() {
    let code = "((("
    let doc = EditorDocument(code: code)
    let coord = makeCoordinator(document: doc)
    let textView = makeTextView(text: code)
    coord.highlightController.applyColors(from: rainbowSettings())

    coord.highlightController.updateBracketHighlights(in: textView)

    // Unmatched brackets should still get rainbow-colored.
    #expect(textView.highlightedRanges.count == 3)
  }

  // MARK: - switchDocument regression tests

  @Test
  func switchDocumentFromLongerToShorterBuffer() {
    let longCode = String(repeating: "(a) ", count: 200) // ~800 chars
    let shortCode = "(b)"
    let longDoc = EditorDocument(code: longCode)
    let shortDoc = EditorDocument(code: shortCode)
    let coord = makeCoordinator(document: longDoc)
    let textView = makeTextView(text: longCode)
    coord.documentObserver.currentDocument = longDoc
    let font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)

    // Move cursor to end of long buffer.
    textView.selectedRange = NSRange(location: longCode.count, length: 0)

    // Switch to shorter buffer — must not crash.
    coord.switchDocument(to: shortDoc, in: textView, font: font, palette: nil)

    #expect(textView.text == shortCode)
    #expect(textView.selectedRange.location <= shortCode.count)
  }

  @Test
  func switchDocumentToNeverLoadedDocument() {
    let longCode = String(repeating: "(a) ", count: 200)
    let shortCode = "(b)"
    let longDoc = EditorDocument(code: longCode)
    let shortDoc = EditorDocument(code: shortCode)
    // shortDoc.savedSelectedRange is nil — never loaded before.
    let coord = makeCoordinator(document: longDoc)
    let textView = makeTextView(text: longCode)
    coord.documentObserver.currentDocument = longDoc
    let font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)

    textView.selectedRange = NSRange(location: longCode.count, length: 0)

    coord.switchDocument(to: shortDoc, in: textView, font: font, palette: nil)

    #expect(shortDoc.savedSelectedRange == nil)
    #expect(textView.selectedRange == NSRange(location: 0, length: 0))
  }

  @Test
  func switchDocumentClampsSavedRange() {
    let longCode = String(repeating: "x", count: 500)
    let shortCode = "abc"
    let longDoc = EditorDocument(code: longCode)
    let shortDoc = EditorDocument(code: shortCode)
    // Simulate a previously-saved cursor beyond the short document's length.
    shortDoc.savedSelectedRange = NSRange(location: 400, length: 0)
    let coord = makeCoordinator(document: longDoc)
    let textView = makeTextView(text: longCode)
    coord.documentObserver.currentDocument = longDoc
    let font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)

    coord.switchDocument(to: shortDoc, in: textView, font: font, palette: nil)

    #expect(textView.selectedRange.location == shortCode.count)
    #expect(textView.selectedRange.length == 0)
  }

  @Test
  func switchDocumentClearsStaleHighlightedRanges() {
    let longCode = "(define (foo) (bar (baz 42)))"
    let shortCode = "(a)"
    let longDoc = EditorDocument(code: longCode)
    let shortDoc = EditorDocument(code: shortCode)
    let coord = makeCoordinator(document: longDoc)
    let textView = makeTextView(text: longCode)
    coord.documentObserver.currentDocument = longDoc
    coord.highlightController.applyColors(from: rainbowSettings())
    let font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)

    // Populate rainbow highlights for the long document.
    coord.highlightController.updateBracketHighlights(in: textView)
    let oldCount = textView.highlightedRanges.count
    #expect(oldCount > 2) // long doc has many brackets

    coord.switchDocument(to: shortDoc, in: textView, font: font, palette: nil)

    // All highlighted ranges must be within the short document's bounds.
    let textLength = (textView.text as NSString).length
    for range in textView.highlightedRanges {
      #expect(
        range.range.location + range.range.length <= textLength,
        "Stale highlight range \(range.range) exceeds text length \(textLength)"
      )
    }
  }

  @Test
  func switchDocumentClearsStaleMatchHighlight() {
    let codeA = "(define (foo) bar)"
    let codeB = "x"
    let docA = EditorDocument(code: codeA)
    let docB = EditorDocument(code: codeB)
    let coord = makeCoordinator(document: docA)
    let textView = makeTextView(text: codeA)
    coord.documentObserver.currentDocument = docA
    coord.highlightController.applyColors(from: rainbowSettings())
    let font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)

    // Place cursor after '(' at position 0 to trigger a match highlight.
    textView.selectedRange = NSRange(location: 1, length: 0)
    coord.textViewDidChangeSelection(textView)

    // Verify a match highlight exists with a range beyond codeB's length.
    let matchRanges = textView.highlightedRanges.filter {
      $0.range.location >= codeB.count
    }
    #expect(!matchRanges.isEmpty, "Expected match highlight beyond codeB length")

    // Switch to the very short document — stale match must not carry over.
    coord.switchDocument(to: docB, in: textView, font: font, palette: nil)

    let textLength = (textView.text as NSString).length
    for range in textView.highlightedRanges {
      #expect(
        range.range.location + range.range.length <= textLength,
        "Stale match range \(range.range) exceeds text length \(textLength)"
      )
    }
  }

  @Test
  func switchDocumentSavesPreviousDocumentState() {
    let codeA = "(hello)"
    let codeB = "(world)"
    let docA = EditorDocument(code: codeA)
    let docB = EditorDocument(code: codeB)
    let coord = makeCoordinator(document: docA)
    let textView = makeTextView(text: codeA)
    coord.documentObserver.currentDocument = docA
    let font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)

    textView.selectedRange = NSRange(location: 5, length: 0)

    coord.switchDocument(to: docB, in: textView, font: font, palette: nil)

    #expect(docA.savedSelectedRange == NSRange(location: 5, length: 0))
  }

  @Test
  func switchDocumentRemovesFlashOverlay() {
    let codeA = "(define (foo) bar)"
    let codeB = "hello"
    let docA = EditorDocument(code: codeA)
    let docB = EditorDocument(code: codeB)
    let coord = makeCoordinator(document: docA)
    let textView = makeTextView(text: codeA)
    coord.documentObserver.currentDocument = docA
    coord.highlightController.applyColors(from: rainbowSettings())
    let font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)

    let subviewCountBefore = textView.subviews.count

    // Trigger a bracket match flash by moving cursor next to '('.
    textView.selectedRange = NSRange(location: 1, length: 0)
    coord.textViewDidChangeSelection(textView)

    #expect(
      textView.subviews.count > subviewCountBefore,
      "Expected flash overlay subview after bracket match"
    )

    coord.switchDocument(to: docB, in: textView, font: font, palette: nil)

    #expect(
      textView.subviews.count == subviewCountBefore,
      "Flash overlay should be removed after document switch"
    )
  }
}
