import Foundation
import Testing

@testable import Ruckus

@Suite
@MainActor
struct EditorStoreTests {

  private func observeCodeReplacement(
    for doc: EditorDocument
  ) -> (capture: CodeCapture, token: NSObjectProtocol) {
    let capture = CodeCapture()
    let token = NotificationCenter.default.addObserver(
      forName: EditorDocument.codeReplaced, object: doc, queue: nil
    ) { notification in
      capture.code = notification.userInfo?[EditorDocument.codeReplacedKey] as? String
    }
    return (capture, token)
  }

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

  // MARK: - canExecute

  @Test
  func canExecuteReturnsFalseWithNoActiveDocument() {
    let store = EditorStore()
    #expect(!store.canExecute)
  }

  @Test
  func canExecuteReturnsTrueWhenNotEvaluating() {
    let store = makeStore(paths: ["/files/a.rkt"])
    #expect(store.canExecute)
  }

  @Test
  func canExecuteReturnsFalseWhenEvaluating() {
    let store = makeStore(paths: ["/files/a.rkt"])
    store.activeDocument!.isEvaluating = true
    #expect(!store.canExecute)
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

  // MARK: - hasActiveDocument

  @Test
  func hasActiveDocumentFalseOnFreshStore() {
    let store = EditorStore()
    #expect(!store.hasActiveDocument)
  }

  @Test
  func hasActiveDocumentTrueAfterNewDocument() {
    let store = EditorStore()
    store.newDocument()
    #expect(store.hasActiveDocument)
  }

  // MARK: - canRevert

  @Test
  func canRevertFalseForUntitledDoc() {
    let store = EditorStore()
    store.newDocument()
    #expect(!store.canRevert)
  }

  @Test
  func canRevertTrueWhenDirtyWithPath() {
    let store = makeStore(paths: ["/files/a.rkt"])
    store.activeDocument!.isDirty = true
    #expect(store.canRevert)
  }

  // MARK: - isExecuting

  @Test
  func isExecutingReflectsActiveDocument() {
    let store = makeStore(paths: ["/files/a.rkt"])
    #expect(!store.isExecuting)
    store.activeDocument!.isEvaluating = true
    #expect(store.isExecuting)
  }

  // MARK: - hasOutput

  @Test
  func hasOutputReflectsActiveDocument() {
    let store = makeStore(paths: ["/files/a.rkt"])
    #expect(!store.hasOutput)
    store.activeDocument!.appendOutput("hello", stream: .stdout)
    #expect(store.hasOutput)
  }

  // MARK: - open

  @Test
  func openCreatesDocumentFromFile() async throws {
    let root = try await Backend.shared.getRootPath()
    let path = root.appendingPathComponent("test-\(UUID().uuidString).rkt")
    try await Backend.shared.save("#lang racket/base\n", to: path)
    defer { Task { try? await Backend.shared.deleteFile(atPath: path) } }

    let store = EditorStore()
    try await store.open(path: path)

    #expect(store.documents.count == 1)
    #expect(store.activeDocument?.code == "#lang racket/base\n")
    #expect(store.activeDocument?.path == path)
  }

  @Test
  func openReusesExistingDocument() async throws {
    let root = try await Backend.shared.getRootPath()
    let path = root.appendingPathComponent("test-\(UUID().uuidString).rkt")
    try await Backend.shared.save("#lang racket/base\n", to: path)
    defer { Task { try? await Backend.shared.deleteFile(atPath: path) } }

    let store = EditorStore()
    try await store.open(path: path)
    let firstDocId = store.activeDocument?.id
    try await store.open(path: path)

    #expect(store.documents.count == 1)
    #expect(store.activeDocument?.id == firstDocId)
  }

  // MARK: - save

  @Test
  func saveUntitledDocument() async throws {
    let store = EditorStore()
    store.newDocument()
    let doc = store.activeDocument!
    doc.title = "test-\(UUID().uuidString)"

    var savedPath: String?
    defer {
      if let path = savedPath {
        Task { try? await Backend.shared.deleteFile(atPath: path) }
      }
    }

    try await store.save(doc)
    savedPath = doc.path

    #expect(!doc.isDirty)
    #expect(doc.path != nil)
    #expect(doc.title.hasSuffix(".rkt"))

    let content = try await Backend.shared.readFile(atPath: doc.path!)
    #expect(content == doc.code)
  }

  // MARK: - execute

  @Test
  func executeRunsScript() async throws {
    try await Backend.ensureExecutorStepInstalled()
    let root = try await Backend.shared.getRootPath()
    let path = root.appendingPathComponent("test-\(UUID().uuidString).rkt")
    try await Backend.shared.save("#lang racket/base\n(displayln \"hello\")\n", to: path)
    defer { Task { try? await Backend.shared.deleteFile(atPath: path) } }

    let store = EditorStore()
    try await store.open(path: path)
    let doc = store.activeDocument!

    await store.execute()

    let executionId = doc.executionId
    #expect(executionId != nil)

    if let executionId {
      _ = try await ExecutionRegistry.shared.awaitCompletion(of: executionId)
    }

    #expect(!doc.isEvaluating)
    #expect(doc.hasOutput)
  }

  // MARK: - formatActiveDocument

  @Test
  func formatActiveDocumentPostsFormattedCode() async {
    let store = EditorStore()
    store.newDocument()
    let doc = store.activeDocument!
    doc.code = "#lang racket/base\n(  +   1    2  )\n"

    let (capture, token) = observeCodeReplacement(for: doc)
    defer { NotificationCenter.default.removeObserver(token) }

    await store.formatActiveDocument()

    #expect(capture.code != nil)
    #expect(capture.code?.contains("(+ 1 2)") == true)
  }

  // MARK: - revert

  @Test
  func revertRestoresFileContent() async throws {
    let root = try await Backend.shared.getRootPath()
    let path = root.appendingPathComponent("test-\(UUID().uuidString).rkt")
    let originalContent = "#lang racket/base\n(displayln \"original\")\n"
    try await Backend.shared.save(originalContent, to: path)
    defer { Task { try? await Backend.shared.deleteFile(atPath: path) } }

    let store = EditorStore()
    try await store.open(path: path)
    let doc = store.activeDocument!
    doc.code = "modified code"

    let (capture, token) = observeCodeReplacement(for: doc)
    defer { NotificationCenter.default.removeObserver(token) }

    await store.revert()

    #expect(capture.code == originalContent)
  }

  // MARK: - close while executing

  @Test
  func closeWhileExecutingStopsExecution() {
    let store = EditorStore()
    store.newDocument()
    let doc = store.activeDocument!
    doc.isEvaluating = true
    let executionId = UInt64.random(in: 1000...UInt64.max)
    doc.executionId = executionId
    ExecutionRegistry.shared.register(doc, executionId: executionId)

    store.close(doc)

    #expect(!doc.isEvaluating)
    #expect(doc.executionId == nil)
  }

  // MARK: - didSet fallback via reorderDocuments

  @Test
  func reorderDocumentsExcludingActiveFallsBackToLast() {
    let store = makeStore(paths: ["/files/a.rkt", "/files/b.rkt", "/files/c.rkt"])
    store.selectDocument(store.documents[0])
    let ids = store.documents.map(\.id)
    store.reorderDocuments(to: [ids[1], ids[2]])
    #expect(store.activeDocument?.title == "c.rkt")
  }

  // MARK: - save filename validation (Task 11)

  @Test
  func saveThrowsForFilenameWithSlash() async throws {
    let store = EditorStore()
    store.newDocument()
    let doc = store.activeDocument!
    doc.title = "bad/name"
    await #expect(throws: SaveError.invalidFilename) {
      try await store.save(doc)
    }
  }

  @Test
  func saveThrowsForFilenameWithDoubleDot() async throws {
    let store = EditorStore()
    store.newDocument()
    let doc = store.activeDocument!
    doc.title = "bad..name"
    await #expect(throws: SaveError.invalidFilename) {
      try await store.save(doc)
    }
  }

  @Test
  func saveAppendsRktSuffixWhenMissing() async throws {
    let store = EditorStore()
    store.newDocument()
    let doc = store.activeDocument!
    doc.title = "test-\(UUID().uuidString)"
    let originalTitle = doc.title

    var savedPath: String?
    defer {
      if let path = savedPath {
        Task { try? await Backend.shared.deleteFile(atPath: path) }
      }
    }

    try await store.save(doc)
    savedPath = doc.path

    #expect(doc.title == originalTitle + ".rkt")
  }

  @Test
  func saveLeavesRktSuffixUnchanged() async throws {
    let store = EditorStore()
    store.newDocument()
    let doc = store.activeDocument!
    doc.title = "test-\(UUID().uuidString).rkt"
    let originalTitle = doc.title

    var savedPath: String?
    defer {
      if let path = savedPath {
        Task { try? await Backend.shared.deleteFile(atPath: path) }
      }
    }

    try await store.save(doc)
    savedPath = doc.path

    #expect(doc.title == originalTitle)
  }

  // MARK: - close edge cases (Task 12)

  @Test
  func closeNonExistentDocumentIsNoOp() {
    let store = makeStore(paths: ["/files/a.rkt", "/files/b.rkt"])
    let ghost = EditorDocument(title: "ghost.rkt", code: "")
    let countBefore = store.documents.count
    let titlesBefore = store.documents.map(\.title)
    store.close(ghost)
    #expect(store.documents.count == countBefore)
    #expect(store.documents.map(\.title) == titlesBefore)
  }

  @Test
  func closeAllDocumentsOneByOneAlwaysCreatesUntitled() {
    let store = makeStore(paths: ["/files/a.rkt", "/files/b.rkt", "/files/c.rkt"])

    // Close first
    store.close(store.documents.first(where: { $0.title == "a.rkt" })!)
    #expect(!store.documents.isEmpty)

    // Close second
    store.close(store.documents.first(where: { $0.title == "b.rkt" })!)
    #expect(!store.documents.isEmpty)

    // Close last named document — Untitled should be created
    store.close(store.documents.first(where: { $0.title == "c.rkt" })!)
    #expect(store.documents.count == 1)
    #expect(store.documents[0].title == "Untitled")
    #expect(store.activeDocument != nil)

    // Close the Untitled — a new Untitled should be created
    store.close(store.documents[0])
    #expect(store.documents.count == 1)
    #expect(store.documents[0].title == "Untitled")
    #expect(store.activeDocument != nil)
  }

  // MARK: - importFile (Task 16)

  @Test
  func importFileCreatesDocumentWithCorrectProperties() async throws {
    let tempDir = FileManager.default.temporaryDirectory
    let tempURL = tempDir.appendingPathComponent("test-import-\(UUID().uuidString).rkt")
    let content = "#lang racket/base\n(displayln \"imported\")\n"
    try content.write(to: tempURL, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(at: tempURL) }

    let store = EditorStore()
    let countBefore = store.documents.count
    await store.importFile(from: tempURL)

    #expect(store.documents.count == countBefore + 1)
    let doc = store.documents.last!
    #expect(doc.title == tempURL.lastPathComponent)
    #expect(doc.code == content)
    #expect(doc.path != nil)

    if let path = doc.path {
      defer { Task { try? await Backend.shared.deleteFile(atPath: path) } }
    }
  }

  @Test
  func importFileNonexistentFileAddsNoDocument() async {
    let bogusURL = URL(fileURLWithPath: "/tmp/nonexistent-\(UUID().uuidString).rkt")
    let store = EditorStore()
    let countBefore = store.documents.count
    await store.importFile(from: bogusURL)
    #expect(store.documents.count == countBefore)
  }

  @Test
  func importFileSetsActiveDocument() async throws {
    let tempDir = FileManager.default.temporaryDirectory
    let tempURL = tempDir.appendingPathComponent("test-active-\(UUID().uuidString).rkt")
    let content = "#lang racket/base\n"
    try content.write(to: tempURL, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(at: tempURL) }

    let store = makeStore(paths: ["/files/a.rkt"])
    store.selectDocument(store.documents[0])
    #expect(store.activeDocument?.title == "a.rkt")

    await store.importFile(from: tempURL)

    #expect(store.activeDocument?.title == tempURL.lastPathComponent)
    #expect(store.activeDocument?.id == store.documents.last?.id)

    if let path = store.activeDocument?.path {
      defer { Task { try? await Backend.shared.deleteFile(atPath: path) } }
    }
  }
}

private final class CodeCapture: @unchecked Sendable {
  var code: String?
}
