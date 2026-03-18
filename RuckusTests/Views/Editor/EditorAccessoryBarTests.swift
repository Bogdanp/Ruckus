import Runestone
import Testing
import UIKit

@testable import Ruckus

@Suite
@MainActor
struct EditorAccessoryBarTests {

  private func makeTextView() -> TextView {
    let view = TextView(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
    let theme = EditorTheme(font: .monospacedSystemFont(ofSize: 14, weight: .regular))
    let state = TextViewState(text: "", theme: theme)
    view.setState(state)
    return view
  }

  // MARK: - makeInputAccessoryView

  @Test
  func createsAccessoryView() {
    let textView = makeTextView()
    let bar = EditorAccessoryBar.makeInputAccessoryView(for: textView, palette: nil)
    #expect(bar.frame.height > 0)
  }

  @Test
  func barContainsStackView() {
    let textView = makeTextView()
    let bar = EditorAccessoryBar.makeInputAccessoryView(for: textView, palette: nil)
    let hasStack = bar.subviews.contains { $0 is UIStackView }
    #expect(hasStack)
  }

  @Test
  func barWithPaletteAppliesBackgroundColor() {
    let textView = makeTextView()
    let palette = ColorPalette.dracula
    let bar = EditorAccessoryBar.makeInputAccessoryView(for: textView, palette: palette)
    #expect(bar.backgroundColor == palette.backgroundColor)
  }

  @Test
  func barStackHasTwoRows() {
    let textView = makeTextView()
    let bar = EditorAccessoryBar.makeInputAccessoryView(for: textView, palette: nil)
    let stack = bar.subviews.first { $0 is UIStackView } as? UIStackView
    #expect(stack != nil)
    #expect(stack?.arrangedSubviews.count == 2)
  }

  @Test
  func rowsContainButtons() {
    let textView = makeTextView()
    let bar = EditorAccessoryBar.makeInputAccessoryView(for: textView, palette: nil)
    let stack = bar.subviews.first { $0 is UIStackView } as? UIStackView
    guard let topRow = stack?.arrangedSubviews.first as? UIScrollView else {
      Issue.record("Expected UIScrollView as first row")
      return
    }
    let rowStack = topRow.subviews.first { $0 is UIStackView } as? UIStackView
    #expect(rowStack != nil)
    let buttons = rowStack?.arrangedSubviews.compactMap { $0 as? UIButton } ?? []
    #expect(!buttons.isEmpty)
  }

  @Test
  func paletteColorIsAppliedToFillerView() {
    let textView = makeTextView()
    let palette = ColorPalette.dracula
    let bar = EditorAccessoryBar.makeInputAccessoryView(for: textView, palette: palette)
    let fillerViews = bar.subviews.filter {
      !($0 is UIStackView) && $0.backgroundColor == palette.backgroundColor
    }
    #expect(!fillerViews.isEmpty)
  }
}
