import Foundation

@Observable
class EditorStore {
  var documents: [EditorDocument] = []
  var activeDocumentID: UUID?

  var activeDocument: EditorDocument? {
    guard let id = activeDocumentID else { return nil }
    return documents.first { $0.id == id }
  }

  init() {
    newDocument()
  }

  func newDocument() {
    let doc = EditorDocument(title: "Untitled", code: "#lang racket/base\n\n")
    documents.append(doc)
    activeDocumentID = doc.id
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
  }

  func close(_ doc: EditorDocument) {
    documents.removeAll { $0.id == doc.id }
    if activeDocumentID == doc.id {
      activeDocumentID = documents.last?.id
    }
    if documents.isEmpty {
      newDocument()
    }
  }
}
