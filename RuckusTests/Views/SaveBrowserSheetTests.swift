import Testing

@testable import Ruckus

@Suite
struct SaveBrowserSheetTests {

  // MARK: - validateFilename

  @Test
  func validFilenameReturnsNil() {
    #expect(SaveBrowserSheet.validateFilename("my-script") == nil)
  }

  @Test
  func slashRejected() {
    let error = SaveBrowserSheet.validateFilename("a/b")
    #expect(error != nil)
    #expect(error!.contains("/"))
  }

  @Test
  func doubleDotRejected() {
    let error = SaveBrowserSheet.validateFilename("a..b")
    #expect(error != nil)
    #expect(error!.contains(".."))
  }

  @Test
  func controlCharacterRejected() {
    let error = SaveBrowserSheet.validateFilename("\u{0000}test")
    #expect(error != nil)
  }

  @Test
  func ignorableCodePointRejected() {
    let error = SaveBrowserSheet.validateFilename("\u{00AD}test")
    #expect(error != nil)
  }

  @Test
  func emptyAfterTrimmingReturnsNil() {
    #expect(SaveBrowserSheet.validateFilename("   ") == nil)
  }

  // MARK: - normalizeFilename

  @Test
  func normalizeAppendsRkt() {
    #expect(SaveBrowserSheet.normalizeFilename("script") == "script.rkt")
  }

  @Test
  func normalizeDoesNotDoubleAppend() {
    #expect(SaveBrowserSheet.normalizeFilename("script.rkt") == "script.rkt")
  }
}
