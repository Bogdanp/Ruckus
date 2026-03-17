import Testing

@testable import Ruckus

@Suite
struct FilesystemEntryTests {

  // MARK: - toBrowserEntries

  @Test
  func emptyArrayReturnsEmpty() {
    let entries: [FilesystemEntry] = []
    let result = entries.toBrowserEntries()
    #expect(result.isEmpty)
  }

  @Test
  func fileEntryConvertsCorrectly() {
    let entries: [FilesystemEntry] = [
      .file(File(path: "/root/test.rkt", size: 42))
    ]
    let result = entries.toBrowserEntries()
    #expect(result.count == 1)
    #expect(result[0].name == "test.rkt")
    #expect(result[0].path == "/root/test.rkt")
    #expect(!result[0].isFolder)
  }

  @Test
  func folderEntryConvertsCorrectly() {
    let entries: [FilesystemEntry] = [
      .folder(Folder(path: "/root/Examples"))
    ]
    let result = entries.toBrowserEntries()
    #expect(result.count == 1)
    #expect(result[0].name == "Examples")
    #expect(result[0].path == "/root/Examples")
    #expect(result[0].isFolder)
  }

  @Test
  func foldersAppearBeforeFiles() {
    let entries: [FilesystemEntry] = [
      .file(File(path: "/root/a.rkt", size: 10)),
      .folder(Folder(path: "/root/Zebra")),
      .file(File(path: "/root/b.rkt", size: 20)),
      .folder(Folder(path: "/root/Alpha"))
    ]
    let result = entries.toBrowserEntries()
    #expect(result[0].name == "Alpha")
    #expect(result[1].name == "Zebra")
    #expect(result[2].name == "a.rkt")
    #expect(result[3].name == "b.rkt")
  }

  @Test
  func filesAreSortedAlphabetically() {
    let entries: [FilesystemEntry] = [
      .file(File(path: "/root/c.rkt", size: 10)),
      .file(File(path: "/root/a.rkt", size: 20)),
      .file(File(path: "/root/b.rkt", size: 30))
    ]
    let result = entries.toBrowserEntries()
    #expect(result.map(\.name) == ["a.rkt", "b.rkt", "c.rkt"])
  }

  @Test
  func foldersAreSortedAlphabetically() {
    let entries: [FilesystemEntry] = [
      .folder(Folder(path: "/root/Charlie")),
      .folder(Folder(path: "/root/Alpha")),
      .folder(Folder(path: "/root/Bravo"))
    ]
    let result = entries.toBrowserEntries()
    #expect(result.map(\.name) == ["Alpha", "Bravo", "Charlie"])
  }

  @Test
  func sortIsCaseInsensitive() {
    let entries: [FilesystemEntry] = [
      .file(File(path: "/root/Zebra.rkt", size: 10)),
      .file(File(path: "/root/alpha.rkt", size: 20))
    ]
    let result = entries.toBrowserEntries()
    #expect(result[0].name == "alpha.rkt")
    #expect(result[1].name == "Zebra.rkt")
  }

  @Test
  func extractsLastPathComponent() {
    let entries: [FilesystemEntry] = [
      .file(File(path: "/root/deep/nested/file.rkt", size: 100)),
      .folder(Folder(path: "/root/deep/nested/subfolder"))
    ]
    let result = entries.toBrowserEntries()
    #expect(result[0].name == "subfolder")
    #expect(result[1].name == "file.rkt")
  }

  @Test
  func fileSizeIsPreserved() {
    let entries: [FilesystemEntry] = [
      .file(File(path: "/root/test.rkt", size: 12345))
    ]
    let result = entries.toBrowserEntries()
    if case .file(let size) = result[0].kind {
      #expect(size == 12345)
    } else {
      Issue.record("Expected file kind")
    }
  }
}
