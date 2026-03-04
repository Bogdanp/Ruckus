import Foundation

@Observable
class EditorStore {
  private static let openDocumentPathsKey = "openDocumentPaths"
  private static let activeDocumentPathKey = "activeDocumentPath"

  private(set) var isLoading = true
  var documents: [EditorDocument] = []
  var activeDocumentID: UUID? {
    didSet { saveSession() }
  }

  var activeDocument: EditorDocument? {
    guard let id = activeDocumentID else { return nil }
    return documents.first { $0.id == id }
  }

  init() {
  }

  func newDocument() {
    let doc = EditorDocument(
      title: "Untitled",
      code: """
#lang racket/base

(displayln "Hello, world!")
""")
    documents.append(doc)
    activeDocumentID = doc.id
    saveSession()
  }

  func open(path: String) async throws {
    if let existing = documents.first(where: { $0.path == path }) {
      activeDocumentID = existing.id
      return
    }
    let content = try await Backend.shared.readFile(atPath: path)
    let name = (path as NSString).lastPathComponent
    let doc = EditorDocument(title: name, path: path, code: content)
    documents.append(doc)
    activeDocumentID = doc.id
    saveSession()
  }

  func save(_ doc: EditorDocument) async throws {
    let path: String
    if let existing = doc.path {
      path = existing
    } else {
      let root = try await Backend.shared.getRootPath()
      let filename = doc.title.hasSuffix(".rkt") ? doc.title : doc.title + ".rkt"
      path = (root as NSString).appendingPathComponent(filename)
      doc.path = path
      doc.title = filename
    }
    try await Backend.shared.save(doc.code, to: path)
    doc.isDirty = false
    saveSession()
  }

  func close(_ doc: EditorDocument) {
    documents.removeAll { $0.id == doc.id }
    if activeDocumentID == doc.id {
      activeDocumentID = documents.last?.id
    }
    if documents.isEmpty {
      newDocument()
    }
    saveSession()
  }

  func restoreSession() async {
    defer { isLoading = false }
    guard let relativePaths = UserDefaults.standard.stringArray(forKey: Self.openDocumentPathsKey),
          !relativePaths.isEmpty else {
      newDocument()
      return
    }
    let activeRelativePath = UserDefaults.standard.string(forKey: Self.activeDocumentPathKey)
    let root: String
    do {
      root = try await Backend.shared.getRootPath()
    } catch {
      return
    }
    documents.removeAll()
    activeDocumentID = nil
    var restoredAny = false
    for relativePath in relativePaths {
      let fullPath = (root as NSString).appendingPathComponent(relativePath)
      let name = (relativePath as NSString).lastPathComponent
      do {
        let content = try await Backend.shared.readFile(atPath: fullPath)
        let doc = EditorDocument(title: name, path: fullPath, code: content)
        documents.append(doc)
        if relativePath == activeRelativePath {
          activeDocumentID = doc.id
        }
        restoredAny = true
      } catch {
        continue
      }
    }
    if restoredAny {
      if activeDocumentID == nil {
        activeDocumentID = documents.first?.id
      }
    } else {
      newDocument()
    }
  }

  private static func relativePath(for absolutePath: String) -> String? {
    guard let range = absolutePath.range(of: "/files/") else { return nil }
    return String(absolutePath[range.upperBound...])
  }

  private func saveSession() {
    guard !isLoading else { return }
    let relativePaths = documents.compactMap { $0.path.flatMap(Self.relativePath) }
    UserDefaults.standard.set(relativePaths, forKey: Self.openDocumentPathsKey)
    let activeRelative = activeDocument?.path.flatMap(Self.relativePath)
    UserDefaults.standard.set(activeRelative, forKey: Self.activeDocumentPathKey)
  }
}
