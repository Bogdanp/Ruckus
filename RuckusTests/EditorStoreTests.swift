import Foundation
import Testing

@testable import Ruckus

@Suite
@MainActor
struct EditorStoreTests {

  private func makeStore(paths: [String]) -> EditorStore {
    let store = EditorStore()
    for path in paths {
      store.newDocument()
      let doc = store.documents.last!
      doc.path = path
      doc.title = (path as NSString).lastPathComponent
    }
    return store
  }

  // MARK: - hasOpenDocuments

  @Test
  func hasOpenDocumentsReturnsTrueForOpenFile() {
    let store = makeStore(paths: ["/files/a.rkt"])

    #expect(store.hasOpenDocuments(at: "/files/a.rkt", isFolder: false))
  }

  @Test
  func hasOpenDocumentsReturnsFalseForClosedFile() {
    let store = makeStore(paths: ["/files/a.rkt"])

    #expect(!store.hasOpenDocuments(at: "/files/b.rkt", isFolder: false))
  }

  @Test
  func hasOpenDocumentsReturnsTrueForFolderContainingOpenFile() {
    let store = makeStore(paths: ["/files/Examples/foo.rkt"])

    #expect(store.hasOpenDocuments(at: "/files/Examples", isFolder: true))
  }

  @Test
  func hasOpenDocumentsReturnsFalseForFolderWithNoOpenFiles() {
    let store = makeStore(paths: ["/files/a.rkt"])

    #expect(!store.hasOpenDocuments(at: "/files/Examples", isFolder: true))
  }

  @Test
  func hasOpenDocumentsDoesNotMatchPartialFolderNames() {
    let store = makeStore(paths: ["/files/Examples2/foo.rkt"])

    #expect(!store.hasOpenDocuments(at: "/files/Examples", isFolder: true))
  }

  // MARK: - closeDocuments

  @Test
  func closeDocumentsRemovesMatchingFile() {
    let store = makeStore(paths: ["/files/a.rkt", "/files/b.rkt"])

    store.closeDocuments(affectedByDeletionOf: "/files/a.rkt", isFolder: false)

    let titles = store.documents.map(\.title)
    #expect(titles == ["b.rkt"])
  }

  @Test
  func closeDocumentsRemovesFilesUnderFolder() {
    let store = makeStore(paths: [
      "/files/Examples/foo.rkt",
      "/files/Examples/bar.rkt",
      "/files/a.rkt"
    ])

    store.closeDocuments(affectedByDeletionOf: "/files/Examples", isFolder: true)

    let titles = store.documents.map(\.title)
    #expect(titles == ["a.rkt"])
  }

  @Test
  func closeDocumentsCreatesNewDocWhenAllClosed() {
    let store = makeStore(paths: ["/files/a.rkt"])

    store.closeDocuments(affectedByDeletionOf: "/files/a.rkt", isFolder: false)

    #expect(store.documents.count == 1)
    #expect(store.documents.first?.title == "Untitled")
  }

  @Test
  func closeDocumentsDoesNothingWhenNoMatch() {
    let store = makeStore(paths: ["/files/a.rkt"])

    store.closeDocuments(affectedByDeletionOf: "/files/b.rkt", isFolder: false)

    let titles = store.documents.map(\.title)
    #expect(titles == ["a.rkt"])
  }

  @Test
  func closeDocumentsDoesNotMatchPartialFolderNames() {
    let store = makeStore(paths: ["/files/Examples2/foo.rkt"])

    store.closeDocuments(affectedByDeletionOf: "/files/Examples", isFolder: true)

    let titles = store.documents.map(\.title)
    #expect(titles == ["foo.rkt"])
  }

  // MARK: - reorderDocuments

  @Test
  func reorderDocumentsChangesOrder() {
    let store = makeStore(paths: ["/files/a.rkt", "/files/b.rkt", "/files/c.rkt"])
    let ids = store.documents.map(\.id)

    store.reorderDocuments(to: [ids[2], ids[0], ids[1]])

    let titles = store.documents.map(\.title)
    #expect(titles == ["c.rkt", "a.rkt", "b.rkt"])
  }

  @Test
  func reorderDocumentsPreservesActiveDocument() {
    let store = makeStore(paths: ["/files/a.rkt", "/files/b.rkt", "/files/c.rkt"])
    let ids = store.documents.map(\.id)
    store.selectDocument(store.documents[1])

    store.reorderDocuments(to: [ids[2], ids[0], ids[1]])

    #expect(store.activeDocument?.title == "b.rkt")
  }

  @Test
  func reorderDocumentsIgnoresUnknownIDs() {
    let store = makeStore(paths: ["/files/a.rkt", "/files/b.rkt"])
    let ids = store.documents.map(\.id)

    store.reorderDocuments(to: [ids[1], UUID(), ids[0]])

    let titles = store.documents.map(\.title)
    #expect(titles == ["b.rkt", "a.rkt"])
  }

  // MARK: - close (tab selection)

  @Test
  func closeActiveFirstTabSelectsNext() {
    let store = makeStore(paths: ["/files/a.rkt", "/files/b.rkt", "/files/c.rkt"])
    store.selectDocument(store.documents[0])

    store.close(store.documents[0])

    #expect(store.activeDocument?.title == "b.rkt")
  }

  @Test
  func closeActiveLastTabSelectsPrevious() {
    let store = makeStore(paths: ["/files/a.rkt", "/files/b.rkt", "/files/c.rkt"])
    // activeDocumentID is already c.rkt (last added)

    store.close(store.documents[2])

    #expect(store.activeDocument?.title == "b.rkt")
  }

  @Test
  func closeActiveMiddleTabSelectsNext() {
    let store = makeStore(paths: ["/files/a.rkt", "/files/b.rkt", "/files/c.rkt"])
    store.selectDocument(store.documents[1])

    store.close(store.documents[1])

    #expect(store.activeDocument?.title == "c.rkt")
  }

  @Test
  func closeInactiveTabKeepsActiveTab() {
    let store = makeStore(paths: ["/files/a.rkt", "/files/b.rkt", "/files/c.rkt"])
    store.selectDocument(store.documents[1])

    store.close(store.documents[0])

    #expect(store.activeDocument?.title == "b.rkt")
  }
}
