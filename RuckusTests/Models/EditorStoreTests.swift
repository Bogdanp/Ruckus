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
    #expect(store.documents.map(\.title) == ["b.rkt"])
  }

  @Test
  func closeDocumentsRemovesFilesUnderFolder() {
    let store = makeStore(paths: [
      "/files/Examples/foo.rkt",
      "/files/Examples/bar.rkt",
      "/files/a.rkt"
    ])
    store.closeDocuments(affectedByDeletionOf: "/files/Examples", isFolder: true)
    #expect(store.documents.map(\.title) == ["a.rkt"])
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
    #expect(store.documents.map(\.title) == ["a.rkt"])
  }

  @Test
  func closeDocumentsDoesNotMatchPartialFolderNames() {
    let store = makeStore(paths: ["/files/Examples2/foo.rkt"])
    store.closeDocuments(affectedByDeletionOf: "/files/Examples", isFolder: true)
    #expect(store.documents.map(\.title) == ["foo.rkt"])
  }

  // MARK: - reorderDocuments

  @Test
  func reorderDocumentsChangesOrder() {
    let store = makeStore(paths: ["/files/a.rkt", "/files/b.rkt", "/files/c.rkt"])
    let ids = store.documents.map(\.id)
    store.reorderDocuments(to: [ids[2], ids[0], ids[1]])
    #expect(store.documents.map(\.title) == ["c.rkt", "a.rkt", "b.rkt"])
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
    #expect(store.documents.map(\.title) == ["b.rkt", "a.rkt"])
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
    store.close(store.documents[2]) // active is already c.rkt (last added)
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

  // MARK: - newDocument

  @Test
  func newDocumentAddsUntitledDocument() {
    let store = EditorStore()
    store.newDocument()
    #expect(store.documents.count == 1)
    #expect(store.documents[0].title == "Untitled")
    #expect(store.documents[0].code.contains("#lang racket/base"))
  }

  @Test
  func newDocumentSetsItAsActive() {
    let store = EditorStore()
    store.newDocument()
    #expect(store.activeDocument != nil)
    #expect(store.activeDocument?.id == store.documents[0].id)
  }

  @Test
  func newDocumentAppendsToExistingDocuments() {
    let store = makeStore(paths: ["/files/a.rkt"])
    let oldCount = store.documents.count
    store.newDocument()
    #expect(store.documents.count == oldCount + 1)
    #expect(store.activeDocument?.title == "Untitled")
  }

  // MARK: - selectDocument

  @Test
  func selectDocumentChangesActiveDocument() {
    let store = makeStore(paths: ["/files/a.rkt", "/files/b.rkt"])
    store.selectDocument(store.documents[0])
    #expect(store.activeDocument?.title == "a.rkt")

    store.selectDocument(store.documents[1])
    #expect(store.activeDocument?.title == "b.rkt")
  }

  // MARK: - activeDocument

  @Test
  func activeDocumentReturnsNilWhenNoDocuments() {
    let store = EditorStore()
    #expect(store.activeDocument == nil)
  }

  @Test
  func activeDocumentReturnsCorrectDocument() {
    let store = makeStore(paths: ["/files/a.rkt", "/files/b.rkt"])
    store.selectDocument(store.documents[0])
    #expect(store.activeDocument === store.documents[0])
  }

  // MARK: - close creates new doc when all closed

  @Test
  func closeLastDocumentCreatesNewUntitled() {
    let store = EditorStore()
    store.newDocument()
    let doc = store.documents[0]
    store.close(doc)
    #expect(store.documents.count == 1)
    #expect(store.documents[0].title == "Untitled")
    #expect(store.activeDocument != nil)
  }

  // MARK: - documents didSet updates activeDocumentID

  @Test
  func removingActiveDocumentFallsBackToLast() {
    let store = makeStore(paths: ["/files/a.rkt", "/files/b.rkt"])
    store.selectDocument(store.documents[0])
    store.close(store.documents[0])
    #expect(store.activeDocument?.title == "b.rkt")
  }

  // MARK: - cleanupTempFile

  @Test
  func cleanupTempFileNoOpWithoutTempPath() {
    let store = EditorStore()
    let doc = EditorDocument()
    store.cleanupTempFile(doc)
    #expect(doc.tempPath == nil)
  }

  // MARK: - relativePath

  @Test
  func relativePathReturnsNilForDocWithoutPath() async {
    let store = EditorStore()
    let doc = EditorDocument()
    let result = await store.relativePath(for: doc)
    #expect(result == nil)
  }
}
