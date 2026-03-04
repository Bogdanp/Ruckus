import Foundation

@MainActor @Observable
class EditorStore {
  private static let openDocumentPathsKey = "openDocumentPaths"
  private static let activeDocumentPathKey = "activeDocumentPath"

  private(set) var isLoading = true
  var documents: [EditorDocument] = []
  private(set) var activeDocumentID: UUID?

  var activeDocument: EditorDocument? {
    guard let id = activeDocumentID else { return nil }
    return documents.first { $0.id == id }
  }

  func selectDocument(_ doc: EditorDocument) {
    activeDocumentID = doc.id
    saveSession()
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
      saveSession()
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
    if let id = doc.executionId {
      AppDelegate.unregister(executionId: id)
      Task { try? await Backend.shared.stopExecution(id) }
    }
    documents.removeAll { $0.id == doc.id }
    if activeDocumentID == doc.id {
      activeDocumentID = documents.last?.id
    }
    if documents.isEmpty {
      newDocument()
    }
    saveSession()
  }

  func execute() async {
    guard let doc = activeDocument else { return }
    if doc.isDirty {
      do {
        try await save(doc)
      } catch {
        doc.output = "Save failed: \(error.localizedDescription)"
        return
      }
    }
    let path: String
    if let savedPath = doc.path {
      path = savedPath
    } else {
      do {
        let tempPath = try await Backend.shared.makeTempPath()
        try await Backend.shared.save(doc.code, to: tempPath)
        doc.tempPath = tempPath
        path = tempPath
      } catch {
        doc.output = "Failed to create temp file: \(error.localizedDescription)"
        return
      }
    }
    doc.output = ""
    doc.isEvaluating = true
    do {
      let id = try await Backend.shared.executeScript(atPath: path)
      doc.executionId = id
      AppDelegate.register(doc, executionId: id)
      AppDelegate.step(id)
    } catch {
      doc.output = error.localizedDescription
      doc.isEvaluating = false
      cleanupTempFile(doc)
    }
  }

  func stopExecution() async {
    guard let doc = activeDocument, let id = doc.executionId else { return }
    do {
      try await Backend.shared.stopExecution(id)
    } catch {
      doc.output += "\nStop failed: \(error.localizedDescription)"
    }
  }

  func revert() async {
    guard let doc = activeDocument, let path = doc.path else { return }
    do {
      let content = try await Backend.shared.readFile(atPath: path)
      doc.code = content
      doc.isDirty = false
    } catch {
      doc.output = "Revert failed: \(error.localizedDescription)"
    }
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

  func cleanupTempFile(_ doc: EditorDocument) {
    guard let tempPath = doc.tempPath else { return }
    doc.tempPath = nil
    Task {
      try? await Backend.shared.deleteFile(atPath: tempPath)
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
