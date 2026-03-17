import Testing
import UIKit

@testable import Ruckus

@Suite
@MainActor
struct CompletionPopoverTests {

  private func makePopover() -> CompletionPopover {
    CompletionPopover { _ in }
  }

  private func internalTableView(of popover: CompletionPopover) -> UITableView {
    guard let table = popover.subviews.first(where: { $0 is UITableView }) as? UITableView else {
      preconditionFailure("CompletionPopover must contain a UITableView")
    }
    return table
  }

  // MARK: - init

  @Test
  func startsHidden() {
    let popover = makePopover()
    #expect(popover.isHidden)
  }

  // MARK: - update

  @Test
  func updateShowsPopoverWithItems() {
    let popover = makePopover()
    popover.update(items: ["define", "display"], prefix: "d")
    #expect(!popover.isHidden)
  }

  @Test
  func updateHidesPopoverWithEmptyItems() {
    let popover = makePopover()
    popover.update(items: ["define"], prefix: "d")
    #expect(!popover.isHidden)

    popover.update(items: [], prefix: "")
    #expect(popover.isHidden)
  }

  @Test
  func updateSetsCorrectRowCount() {
    let popover = makePopover()
    popover.update(items: ["alpha", "beta", "gamma"], prefix: "")
    let table = internalTableView(of: popover)
    #expect(popover.tableView(table, numberOfRowsInSection: 0) == 3)
  }

  @Test
  func updateSizesPopoverToFitItems() {
    let popover = makePopover()
    popover.update(items: ["define", "display"], prefix: "d")
    #expect(popover.frame.height > 0)
    #expect(popover.frame.width > 0)
  }

  @Test
  func updateCapsHeightAtMaxVisible() {
    let popover = makePopover()
    let items = (0..<20).map { "item\($0)" }
    popover.update(items: items, prefix: "item")
    #expect(popover.frame.height == CGFloat(32 * 5))
  }

  // MARK: - dismiss

  @Test
  func dismissHidesPopover() {
    let popover = makePopover()
    popover.update(items: ["define"], prefix: "d")
    #expect(!popover.isHidden)

    popover.dismiss()
    #expect(popover.isHidden)
  }

  @Test
  func dismissClearsItems() {
    let popover = makePopover()
    popover.update(items: ["define", "display"], prefix: "d")
    popover.dismiss()
    let table = internalTableView(of: popover)
    #expect(popover.tableView(table, numberOfRowsInSection: 0) == 0)
  }

  // MARK: - updateFont

  @Test
  func updateFontChangesFont() {
    let popover = makePopover()
    let newFont = UIFont.monospacedSystemFont(ofSize: 20, weight: .bold)
    popover.updateFont(newFont)
    popover.update(items: ["test"], prefix: "t")
    let table = internalTableView(of: popover)
    let cell = popover.tableView(table, cellForRowAt: IndexPath(row: 0, section: 0))
    let font = cell.textLabel?.attributedText?.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
    #expect(font == newFont)
  }

  // MARK: - updatePalette

  @Test
  func updatePaletteChangesBackgroundColor() {
    let popover = makePopover()
    let palette = ColorPalette.dracula
    popover.updatePalette(palette)
    #expect(popover.backgroundColor == palette.gutterBackground)
  }

  @Test
  func updatePaletteNilResetsToDefaults() {
    let popover = makePopover()
    popover.updatePalette(.dracula)
    popover.updatePalette(nil)
    #expect(popover.backgroundColor == .secondarySystemBackground)
  }

  // MARK: - didSelectRow

  @Test
  func didSelectRowInsertsRemainder() {
    var inserted: String?
    let popover = CompletionPopover { inserted = $0 }
    popover.update(items: ["define-values"], prefix: "define")

    let table = internalTableView(of: popover)
    popover.tableView(table, didSelectRowAt: IndexPath(row: 0, section: 0))

    #expect(inserted == "-values")
    #expect(popover.isHidden)
  }

  // MARK: - cellForRowAt

  @Test
  func cellHighlightsPrefix() {
    let popover = makePopover()
    popover.update(items: ["define-values"], prefix: "define")
    let table = internalTableView(of: popover)
    let cell = popover.tableView(table, cellForRowAt: IndexPath(row: 0, section: 0))
    let text = cell.textLabel?.attributedText
    #expect(text?.string == "define-values")
    let prefixColor = text?.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor
    let suffixColor = text?.attribute(.foregroundColor, at: 6, effectiveRange: nil) as? UIColor
    #expect(prefixColor != suffixColor)
  }
}
