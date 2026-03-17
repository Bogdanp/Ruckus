import Testing

@testable import Ruckus

@Suite
struct BrowserEntryTests {

  @Test
  func fileEntryIsFolderReturnsFalse() {
    let entry = BrowserEntry(name: "test.rkt", path: "/files/test.rkt", kind: .file(size: 100))
    #expect(!entry.isFolder)
  }

  @Test
  func folderEntryIsFolderReturnsTrue() {
    let entry = BrowserEntry(name: "Examples", path: "/files/Examples", kind: .folder)
    #expect(entry.isFolder)
  }

  @Test
  func idIsPath() {
    let entry = BrowserEntry(name: "test.rkt", path: "/files/test.rkt", kind: .file(size: 100))
    #expect(entry.id == "/files/test.rkt")
  }
}
