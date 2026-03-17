import Runestone
import Testing
import UIKit

@testable import Ruckus

@Suite
@MainActor
struct HighlightControllerTests {

  private func makeTextView(
    text: String,
    frame: CGRect = CGRect(x: 0, y: 0, width: 375, height: 667)
  ) -> TextView {
    let view = TextView(frame: frame)
    let theme = EditorTheme(font: .monospacedSystemFont(ofSize: 14, weight: .regular))
    let state = TextViewState(text: text, theme: theme)
    view.setState(state)

    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
      return view
    }
    let window = UIWindow(windowScene: scene)
    window.addSubview(view)
    view.frame = frame
    view.layoutIfNeeded()
    return view
  }

  private func rainbowSettings() -> EditorSettings {
    let settings = EditorSettings()
    settings.rainbowParentheses = true
    settings.themeName = .dracula
    return settings
  }

  // MARK: - applyColors

  @Test
  func applyColorsEnablesRainbow() {
    let controller = HighlightController()
    controller.applyColors(from: rainbowSettings())
    #expect(controller.rainbowEnabled)
  }

  @Test
  func applyColorsDisablesRainbow() {
    let controller = HighlightController()
    let settings = EditorSettings()
    settings.rainbowParentheses = false
    controller.applyColors(from: settings)
    #expect(!controller.rainbowEnabled)
  }

  @Test
  func applyColorsUsesThemePalette() {
    let controller = HighlightController()
    controller.applyColors(from: rainbowSettings())

    if let palette = ColorThemeName.dracula.palette {
      #expect(controller.rainbowColors == palette.rainbowColors)
      #expect(controller.matchColor == palette.matchHighlightColor)
    }
  }

  // MARK: - updateBracketHighlights

  @Test
  func updateBracketHighlightsWithTextOverload() {
    let controller = HighlightController()
    controller.applyColors(from: rainbowSettings())

    let textView = makeTextView(text: "(a)")
    controller.updateBracketHighlights(text: "(a)", in: textView)

    #expect(textView.highlightedRanges.count == 2)
  }

  // MARK: - clearMatchState

  @Test
  func clearMatchStateResetsState() {
    let controller = HighlightController()
    controller.applyColors(from: rainbowSettings())

    let textView = makeTextView(text: "(abc)")
    textView.selectedRange = NSRange(location: 1, length: 0)
    controller.updateMatchHighlight(in: textView)

    controller.clearMatchState()

    controller.updateBracketHighlights(in: textView)
    #expect(textView.highlightedRanges.count == 2)
  }

  // MARK: - updateMatchHighlight

  @Test
  func updateMatchHighlightAddsRangeAtBracket() {
    let controller = HighlightController()
    controller.applyColors(from: rainbowSettings())

    let textView = makeTextView(text: "(abc)")

    controller.updateBracketHighlights(in: textView)
    let rainbowCount = textView.highlightedRanges.count

    textView.selectedRange = NSRange(location: 1, length: 0)
    controller.updateMatchHighlight(in: textView)

    #expect(textView.highlightedRanges.count == rainbowCount + 1)
  }

  @Test
  func updateMatchHighlightClearsWhenNotAtBracket() {
    let controller = HighlightController()
    controller.applyColors(from: rainbowSettings())

    let textView = makeTextView(text: "(abc)")
    controller.updateBracketHighlights(in: textView)

    textView.selectedRange = NSRange(location: 2, length: 0)
    controller.updateMatchHighlight(in: textView)

    #expect(textView.highlightedRanges.count == 2)
  }
}
