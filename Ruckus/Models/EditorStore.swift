import Foundation
import os

@MainActor @Observable
class EditorStore {
  static let shared = EditorStore()

  private static let openDocumentPathsKey = "openDocumentPaths"
  private static let activeDocumentPathKey = "activeDocumentPath"
  private static let hasInstalledExamplesKey = "hasInstalledExamples"

  private var saveTask: Task<Void, Never>?
  private(set) var isLoading = true
  private(set) var baseCompletions: [String] = []
  private(set) var documents: [EditorDocument] = [] {
    didSet {
      if let id = activeDocumentID, !documents.contains(where: { $0.id == id }) {
        activeDocumentID = documents.last?.id
      }
    }
  }
  private(set) var activeDocumentID: UUID?

  var activeDocument: EditorDocument? {
    guard let id = activeDocumentID else { return nil }
    return documents.first { $0.id == id }
  }

  var hasActiveDocument: Bool { activeDocument != nil }
  var canRevert: Bool { activeDocument?.canRevert ?? false }
  var canExecute: Bool { activeDocument.map { !$0.isEvaluating } ?? false }
  var isExecuting: Bool { activeDocument?.isEvaluating ?? false }
  var hasOutput: Bool { activeDocument?.hasOutput ?? false }

  func reorderDocuments(to ids: [UUID]) {
    var reordered: [EditorDocument] = []
    for id in ids {
      if let doc = documents.first(where: { $0.id == id }) {
        reordered.append(doc)
      }
    }
    documents = reordered
    saveSession()
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
      guard !filename.contains("/"), !filename.contains("..") else {
        throw SaveError.invalidFilename
      }
      path = root.appendingPathComponent(filename)
      doc.path = path
      doc.title = filename
    }
    try await Backend.shared.save(doc.code, to: path)
    doc.isDirty = false
    saveSession()
    ScriptManifest.add(scriptAtPath: path)
  }

  func close(_ doc: EditorDocument) {
    if let id = doc.executionId {
      ExecutionService.shared.finishExecution(executionId: id, doc: doc, result: .stopped)
      Task {
        do {
          try await Backend.shared.stopExecution(id)
        } catch {
          Logger.editor.warning("\(#function): stop execution failed: \(error)")
        }
      }
    }
    if activeDocumentID == doc.id {
      if let idx = documents.firstIndex(where: { $0.id == doc.id }) {
        let nextIndex = documents.index(after: idx)
        if nextIndex < documents.endIndex {
          activeDocumentID = documents[nextIndex].id
        } else if idx > documents.startIndex {
          activeDocumentID = documents[documents.index(before: idx)].id
        } else {
          activeDocumentID = nil
        }
      }
    }
    documents.removeAll { $0.id == doc.id }
    if documents.isEmpty {
      newDocument()
    }
    saveSession()
  }

  func execute() async {
    guard let doc = activeDocument, !doc.isEvaluating else { return }
    let path: String
    if let savedPath = doc.path {
      if doc.isDirty {
        do {
          try await save(doc)
        } catch {
          doc.appendOutput("Save failed: \(error.localizedDescription)", stream: .stderr)
          return
        }
      }
      path = savedPath
    } else {
      do {
        let tempPath = try await Backend.shared.makeTempPath()
        try await Backend.shared.save(doc.code, to: tempPath)
        doc.tempPath = tempPath
        path = tempPath
      } catch {
        doc.appendOutput("Failed to create temp file: \(error.localizedDescription)", stream: .stderr)
        return
      }
    }
    doc.clearOutput()
    doc.isEvaluating = true
    do {
      let id = try await Backend.shared.executeScript(atPath: path)
      doc.executionId = id
      ExecutionRegistry.shared.register(doc, executionId: id)
      ExecutionService.shared.runExecution(id)
    } catch {
      doc.appendOutput(error.localizedDescription, stream: .stderr)
      doc.isEvaluating = false
      cleanupTempFile(doc)
    }
  }

  func stopExecution() async {
    guard let doc = activeDocument, let id = doc.executionId else { return }
    do {
      try await Backend.shared.stopExecution(id)
    } catch {
      doc.appendOutput("\nStop failed: \(error.localizedDescription)", stream: .stderr)
    }
  }

  func importFile(from url: URL) async {
    let filename = url.lastPathComponent
    guard let content = try? String(contentsOf: url, encoding: .utf8) else {
      Logger.editor.warning("\(#function): failed to read imported file: \(url.lastPathComponent)")
      return
    }
    let root = try? await Backend.shared.getRootPath()
    let doc = EditorDocument(title: filename, code: content)
    if let root {
      let destPath = root.appendingPathComponent(filename)
      do {
        try await Backend.shared.save(content, to: destPath)
      } catch {
        Logger.editor.warning("\(#function): failed to save imported file: \(error)")
      }
      doc.path = destPath
    }
    documents.append(doc)
    activeDocumentID = doc.id
    saveSession()
    if let destPath = doc.path {
      ScriptManifest.add(scriptAtPath: destPath)
    }
  }

  func formatActiveDocument() async {
    guard let doc = activeDocument else { return }
    do {
      let formatted = try await Backend.shared.formatProgram(doc.code)
      doc.code = formatted
    } catch {
      doc.appendOutput("Format failed: \(error.localizedDescription)", stream: .stderr)
    }
  }

  func revert() async {
    guard let doc = activeDocument, let path = doc.path else { return }
    do {
      let content = try await Backend.shared.readFile(atPath: path)
      doc.code = content
      doc.isDirty = false
    } catch {
      doc.appendOutput("Revert failed: \(error.localizedDescription)", stream: .stderr)
    }
  }

  func restoreSession() async {
    defer { isLoading = false }
    #if DEBUG
    let shouldInstallExamples = true
    #else
    let shouldInstallExamples = !UserDefaults.standard.bool(forKey: Self.hasInstalledExamplesKey)
    #endif
    if shouldInstallExamples {
      do {
        try await Backend.shared.installExamples()
      } catch {
        Logger.backend.error("\(#function): failed to install examples: \(error)")
      }
      UserDefaults.standard.set(true, forKey: Self.hasInstalledExamplesKey)
    }
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
      Logger.session.error("\(#function): failed to get root path: \(error)")
      newDocument()
      return
    }
    documents.removeAll()
    activeDocumentID = nil
    var restoredAny = false
    for relativePath in relativePaths {
      let fullPath = root.appendingPathComponent(relativePath)
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
        Logger.session.warning("\(#function): failed to restore document at \(fullPath): \(error)")
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
    await refreshScriptManifest()
    await fetchBaseCompletions()
  }

  private func fetchBaseCompletions() async {
    do {
      baseCompletions = try await Backend.shared.getRacketBaseSymbols().sorted()
    } catch {
      Logger.backend.warning("\(#function): failed to fetch base completions: \(error)")
    }
  }

  func hasOpenDocuments(at path: String, isFolder: Bool) -> Bool {
    if isFolder {
      let prefix = path + "/"
      return documents.contains { $0.path?.hasPrefix(prefix) == true }
    } else {
      return documents.contains { $0.path == path }
    }
  }

  func closeDocuments(affectedByDeletionOf path: String, isFolder: Bool) {
    let docsToClose: [EditorDocument]
    if isFolder {
      let prefix = path + "/"
      docsToClose = documents.filter { $0.path?.hasPrefix(prefix) == true }
    } else {
      docsToClose = documents.filter { $0.path == path }
    }
    for doc in docsToClose {
      close(doc)
    }
  }

  func cleanupTempFile(_ doc: EditorDocument) {
    guard let tempPath = doc.tempPath else { return }
    doc.tempPath = nil
    Task {
      do {
        try await Backend.shared.deleteFile(atPath: tempPath)
      } catch {
        Logger.editor.warning("\(#function): temp file cleanup failed: \(error)")
      }
    }
  }

  private func refreshScriptManifest() async {
    guard let root = try? await Backend.shared.getRootPath() else { return }
    var scripts = [String]()
    var queue = [root]
    while !queue.isEmpty {
      let dir = queue.removeFirst()
      let entries = (try? await Backend.shared.listFiles(atPath: dir)) ?? []
      for entry in entries {
        switch entry {
        case .file(let file) where file.path.hasSuffix(".rkt"):
          scripts.append(file.path.relativePath(from: root))
        case .folder(let folder):
          queue.append(folder.path)
        default:
          break
        }
      }
    }
    ScriptManifest.update(rootPath: root, scripts: scripts)
  }

  func relativePath(for doc: EditorDocument) async -> String? {
    guard let path = doc.path,
          let root = try? await Backend.shared.getRootPath(),
          path.hasPrefix(root) else { return nil }
    return path.relativePath(from: root)
  }

  private func saveSession() {
    guard !isLoading else { return }
    saveTask?.cancel()
    saveTask = Task {
      try? await Task.sleep(for: .milliseconds(100))
      guard !Task.isCancelled else { return }
      do {
        try await saveSessionAsync()
      } catch {
        Logger.session.warning("\(#function): failed to save session: \(error)")
      }
    }
  }

  private func saveSessionAsync() async throws {
    let root = try await Backend.shared.getRootPath()
    var relativePaths = [String]()
    for doc in documents {
      guard let path = doc.path, path.hasPrefix(root) else { continue }
      relativePaths.append(path.relativePath(from: root))
    }
    UserDefaults.standard.set(relativePaths, forKey: Self.openDocumentPathsKey)
    var activeRelative: String?
    if let doc = activeDocument, let path = doc.path, path.hasPrefix(root) {
      activeRelative = path.relativePath(from: root)
    }
    UserDefaults.standard.set(activeRelative, forKey: Self.activeDocumentPathKey)
  }
}
